#include "llvm/CodeGen/GCMetadataPrinter.h"
#include "llvm/CodeGen/AsmPrinter.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/DataLayout.h"
#include "llvm/MC/MCStreamer.h"
#include "llvm/Target/TargetLoweringObjectFile.h"
#include "llvm/Target/TargetMachine.h"
#include "llvm/Target/TargetSubtargetInfo.h"

using namespace llvm;

namespace {
	class RgcPrinter : public GCMetadataPrinter {
	public:
		virtual void finishAssembly(Module &M, GCModuleInfo &Info,
					    AsmPrinter &AP) override;
	};
}

static GCMetadataPrinterRegistry::Add<RgcPrinter> X("rhine", "md printer");

void RgcPrinter::finishAssembly(Module &M, GCModuleInfo &Info, AsmPrinter &AP) {
	MCStreamer &OS = AP.OutStreamer;
	unsigned IntPtrSize = AP.TM.getSubtargetImpl()->getDataLayout()->getPointerSize();

	// Put this in the data section.
	OS.SwitchSection(AP.getObjFileLowering().getDataSection());

	// For each function...
	for (GCModuleInfo::FuncInfoVec::iterator FI = Info.funcinfo_begin(),
		     FE = Info.funcinfo_end(); FI != FE; ++FI) {
		GCFunctionInfo &MD = **FI;

		// A compact GC layout. Emit this data structure:
		//
		// struct {
		//   int32_t PointCount;
		//   void *SafePointAddress[PointCount];
		//   int32_t StackFrameSize; // in words
		//   int32_t StackArity;
		//   int32_t LiveCount;
		//   int32_t LiveOffsets[LiveCount];
		// } __gcmap_<FUNCTIONNAME>;

		// Align to address width.
		// AP.EmitAlignment(IntPtrSize == 4 ? 2 : 3);

		// Emit PointCount.
		OS.AddComment("safe point count");
		AP.EmitInt32(MD.size());

		// And each safe point...
		for (GCFunctionInfo::iterator PI = MD.begin(),
			     PE = MD.end(); PI != PE; ++PI) {
			// Emit the address of the safe point.
			OS.AddComment("safe point address");
			MCSymbol *Label = PI->Label;
			AP.EmitLabelPlusOffset(Label/*Hi*/, 0/*Offset*/, 4/*Size*/);
		}

		// Stack information never change in safe points! Only print info from the
		// first call-site.
		GCFunctionInfo::iterator PI = MD.begin();

		// Emit the stack frame size.
		OS.AddComment("stack frame size (in words)");
		AP.EmitInt32(MD.getFrameSize() / IntPtrSize);

		// Emit stack arity, i.e. the number of stacked arguments.
		unsigned RegisteredArgs = IntPtrSize == 4 ? 5 : 6;
		unsigned StackArity = MD.getFunction().arg_size() > RegisteredArgs ?
			MD.getFunction().arg_size() - RegisteredArgs : 0;
		OS.AddComment("stack arity");
		AP.EmitInt32(StackArity);

		// Emit the number of live roots in the function.
		OS.AddComment("live root count");
		AP.EmitInt32(MD.live_size(PI));

		// And for each live root...
		for (GCFunctionInfo::live_iterator LI = MD.live_begin(PI),
			     LE = MD.live_end(PI);
		     LI != LE; ++LI) {
			// Emit live root's offset within the stack frame.
			OS.AddComment("stack index (offset / wordsize)");
			AP.EmitInt32(LI->StackOffset);
		}
	}
}
