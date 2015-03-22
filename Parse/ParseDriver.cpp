// $Id$
/** \file driver.cc Implementation of the example::Driver class. */

#include <fstream>
#include <sstream>

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

void ParseDriver::error(const class location& l,
                        const std::string& m)
{
  *ErrorStream << l << ": " << m << std::endl;
}

void ParseDriver::error(const std::string& m)
{
  *ErrorStream << m << std::endl;
}
}
