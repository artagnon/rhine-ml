// $Id$
/** \file driver.cc Implementation of the example::Driver class. */

#include <fstream>
#include <sstream>

#include "rhine/ParseDriver.h"
#include "rhine/Lexer.h"

namespace rhine {
Driver::Driver(class SExpr& Expr) : TraceScanning(false),
                                    TraceParsing(false),
                                    Root(Expr)
{
}

bool Driver::parseStream(std::istream& in, const std::string& sname)
{
  streamname = sname;

  Lexer Lexx(&in);
  Lexx.set_debug(TraceScanning);
  this->lexer = &Lexx;

  Parser Parseyy(*this);
  Parseyy.set_debug_level(TraceParsing);
  return !Parseyy.parse();
}

bool Driver::parse_file(const std::string &filename)
{
  std::ifstream in(filename, std::ifstream::in);
  if (!in.good()) return false;
  return parseStream(in, filename);
}

bool Driver::parseString(const std::string &input, const std::string& sname)
{
  std::istringstream iss(input);
  return parseStream(iss, sname);
}

void Driver::error(const class location& l,
		   const std::string& m)
{
  std::cerr << l << ": " << m << std::endl;
}

void Driver::error(const std::string& m)
{
  std::cerr << m << std::endl;
}
}
