#include "alt.h"

#include "main.h"

namespace A {

int athing = 1;
std::tuple<int, int> qweqweq;

}

int main_alt() {
	A::qweqweq = std::make_tuple(A::athing, 1111);
	return 0;
}
