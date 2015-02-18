#ifndef PARSETREE_H
#define PARSETREE_H

namespace rhine {
class Sexpr {};

class ConsCell : virtual Sexpr {
  Sexpr *First;
  Sexpr *Rest;
};

#endif
