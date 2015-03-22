// $Id$
/** \file driver.cc Implementation of the example::Driver class. */

#include <fstream>
#include <sstream>
#include <iomanip>
#include <unistd.h>

#include "rhine/ParseDriver.h"
#include "rhine/Lexer.h"
#include "Parser.hpp"

namespace rhine {
bool ParseDriver::parseStream(std::istream &in, const std::string &sname) {
  StreamName = sname;

  rhine::Lexer Lexx(&in, ErrorStream);
  Lexx.set_debug(TraceScanning);
  this->Lexx = &Lexx;

  Parser Parseyy(this);
  Parseyy.set_debug_level(TraceParsing);
  return !Parseyy.parse();
}

bool ParseDriver::parseFile(const std::string &filename) {
  std::ifstream in(filename, std::ifstream::in);
  if (!in.good()) return false;
  return parseStream(in, filename);
}

bool ParseDriver::parseString(const std::string &input,
                              const std::string &sname)
{
  std::istringstream iss(input);
  return parseStream(iss, sname);
}

#define ANSI_COLOR_RED     "\x1b[31;1m"
#define ANSI_COLOR_GREEN   "\x1b[32m"
#define ANSI_COLOR_YELLOW  "\x1b[33;1m"
#define ANSI_COLOR_BLUE    "\x1b[34;1m"
#define ANSI_COLOR_MAGENTA "\x1b[35;1m"
#define ANSI_COLOR_CYAN    "\x1b[36;1m"
#define ANSI_COLOR_WHITE   "\x1b[37;1m"
#define ANSI_COLOR_RESET   "\x1b[0m"

class ColorCode
{
  std::string ColorF;
public:
  ColorCode(std::string Color) : ColorF(Color) {}
  // Necessary to prevent color codes from messing up setw
  friend std::ostream& operator<<(std::ostream& dest, ColorCode const& Code)
  {
    for (char ch : Code.ColorF) {
      dest.put(ch);
    }
    return dest;
  }
};

void ParseDriver::error(const class location& l,
                        const std::string& m)
{
  // TODO: when are these assumptions violated?
  assert(l.begin.filename == l.end.filename);
  assert(l.begin.line == l.end.line);

  std::ifstream InFile(*l.begin.filename);
  std::string ScriptPath = *l.begin.filename;
  char Buffer[PATH_MAX];
  char *CwdP = getcwd(Buffer, PATH_MAX);
  std::string Cwd(CwdP);
  Cwd += "/"; // Cwd is guaranteed to be a directory
  auto MisPair = std::mismatch(Cwd.begin(),
                               Cwd.end(), ScriptPath.begin());
  auto CommonAnchor = Cwd.rfind('/', MisPair.first - Cwd.begin());
  std::string StripString = "";
  if (MisPair.first != Cwd.end()) {
    auto StripComponents = std::count(MisPair.first, Cwd.end(), '/');
    for (int i = 0; i < StripComponents; i++)
      StripString += "../";
  }
  ScriptPath.erase(ScriptPath.begin(),
                   ScriptPath.begin() + CommonAnchor + 1);
  // +1 for the '/'
  ScriptPath = StripString + ScriptPath;
  *ErrorStream << ColorCode(ANSI_COLOR_WHITE) << ScriptPath << ":"
               << l.begin.line << ":" << l.begin.column << ": "
               << ColorCode(ANSI_COLOR_RED) << "error: "
               << ColorCode(ANSI_COLOR_WHITE) << m
               << ColorCode(ANSI_COLOR_RESET) << std::endl;
  if (!InFile)
    return;
  std::string Scratch;
  for (int i = 0; i < l.begin.line; i++)
    std::getline(InFile, Scratch);
  *ErrorStream << Scratch << std::endl << std::setfill(' ')
               << std::setw(l.begin.column)
               << ColorCode(ANSI_COLOR_GREEN) << '^';
  unsigned int end_col = l.end.column > 0 ? l.end.column - 1 : 0;
  if (end_col != l.begin.column)
    *ErrorStream << std::setfill('~')
                 << std::setw(end_col - l.begin.column) << '~';
  *ErrorStream << ColorCode(ANSI_COLOR_RESET) << std::endl;

}

void ParseDriver::error(const std::string& m)
{
  *ErrorStream << m << std::endl;
}
}
