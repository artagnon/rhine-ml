// -*- C++ -*-

#ifndef CODEGEN_H
#define CODEGEN_H

#include <string>

void toplevelJit(std::string Filename, bool Debug = false);
std::string parsePrgString(std::string PrgString, bool Debug = false);

#endif
