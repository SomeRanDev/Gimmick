#include "alt.hpp"

namespace test {
namespace aa2 {
namespace qqq {

int fd = 23 + A::athing;
int aaa = 1;
int aas = 12;
const int bla = 12;
int bla2 = 23;
const int dasa = bla + 1;
std::string blastring = "";

}
}
}

int ttt = test::aa2::qqq::bla2;
int bla43 = 12;
int bla = test::aa2::qqq::aas;
std::tuple<int, int> atestaagin = std::make_tuple(12, 43);
const std::tuple<std::string, std::string> blablaabla = std::make_tuple("qreewq", "fdklskflds");

int main() {
	qqq::aa2::test::aas = 1 + 12;
	qqq::aa2::test::aas = 1;
	qqq::aa2::test::aas = 2;
	qqq::aa2::test::aas = qqq::aa2::test::bla * 33;
	qqq::aa2::test::blastring = "test";
}
