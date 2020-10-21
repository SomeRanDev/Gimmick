#include "alt.h"

#include "main.h"

namespace A {

int athing = 1;
std::tuple<int, int> qweqweq;

}

int bla = 32;

std::string bla2() {
	return "test";
}

std::string toCpp() {
	return bla2() + "test";
}

int main_alt() {
	A::qweqweq = std::make_tuple(A::athing, 1111);
	return 0;
}
