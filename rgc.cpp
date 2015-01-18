#include "llvm/IR/GCStrategy.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/Value.h"

using namespace llvm;

namespace {
class StatepointGC : public GCStrategy {
public:
  StatepointGC() {
    UseStatepoints = true;
    // These options are all gc.root specific, we specify them so that the
    // gc.root lowering code doesn't run.
    InitRoots = false;
    NeededSafePoints = 0;
    UsesMetadata = false;
    CustomRoots = false;
  }
  Optional<bool> isGCManagedPointer(const Value *V) const override {
    // Method is only valid on pointer typed values.
    PointerType *PT = cast<PointerType>(V->getType());
    // For the sake of this example GC, we arbitrarily pick addrspace(1) as our
    // GC managed heap.  We know that a pointer into this heap needs to be
    // updated and that no other pointer does.
    return (1 == PT->getAddressSpace());
  }
};
}

static GCRegistry::Add<StatepointGC>
X("rgc", "Rhine GC");
