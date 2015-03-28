//-*- C++ -*-

#ifndef TOPLEVEL_H
#define TOPLEVEL_H

#include <iostream>
#include <string>

typedef int (*MainFTy)();

namespace rhine {
MainFTy jitFacade(std::string Filename, bool Debug);
}

#endif
