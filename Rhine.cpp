#include "rhine/OptionParser.h"
#include "rhine/CodeGen.h"

#include <iostream>

enum OptionIndex {
  UNKNOWN,
  DEBUG,
  HELP
};

const option::Descriptor Usage[] =
  {
    {UNKNOWN, 0, "", "", option::Arg::None,
     "USAGE: [options]\n\nOptions:"},
    {DEBUG, 0, "", "debug", option::Arg::None,
     " --debug\t\tDebug lexer and parser"},
    {HELP, 0, "", "help", option::Arg::None,
     " --help\t\tPrint usage and exit"},
    {}
  };

int main(int argc, char *argv[]) {
  argc-=(argc>0); argv+=(argc>0); // skip program name argv[0] if present
  option::Stats  Stats(Usage, argc, argv);
  option::Option* Options = new option::Option[Stats.options_max];
  option::Option* Buffer  = new option::Option[Stats.buffer_max];
  option::Parser parse(Usage, argc, argv, Options, Buffer);

  if (parse.error())
    return 1;

  if (Options[HELP]) {
    option::printUsage(std::cout, Usage);
    return 0;
  }

  for (option::Option *Opt = Options[UNKNOWN]; Opt; Opt = Opt->next())
    std::cout << "Unknown option: " <<
      std::string(Opt->name, Opt->namelen) << std::endl;
  if (Options[UNKNOWN])
    return 1;

  toplevelJit("", Options[DEBUG]);
  return 0;
}
