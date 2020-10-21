#include "main.h"

#include "alt.h"

namespace test {
namespace aa2 {
namespace qqq {

int fd = 0;
int aaa = 1;
int aas = 12;
const int bla = 12;
int bla2 = 23;
const int dasa = bla + 1;
std::string blastring = "";

}
}
}

int ttt = 0;
int bla43 = 12;
int bla = 0;
std::tuple<int, int> atestaagin = std::make_tuple(12, 43);
const std::tuple<std::string, std::string> blablaabla = std::make_tuple("qreewq", "fdklskflds");
int newthing = (32);

int bla4343() {
	int bla = 12;
	bla++;
	if(bla == 13) {
		int fdhjsfdsk = 4343;
		bla--;
	} else if(bla == 14) {
		bla++;
	} else {
		bla++;
	}
	{
		int bla = 12;
		bla++;
		bla++;
	}
	while(true) {
		bla++;
	}
	while(bla < 300) {
		bla--;
		bla--;
	}
	return (0);
}

void fjdklsfjs() {
	int fdsfs = 32;
	fdsfs--;
}

int get_aaaa() {
	int fds = 32;
	return 32;
}

double set_aaaa(int i) {
	return 32;
}

int fkd = 0;

#include "api/attributes/basic.h"

int main() {
	main_alt();
	test::aa2::qqq::fd = 23 + A::athing;
	test::aa2::qqq::aas = 1 + 12;
	test::aa2::qqq::aas = 1;
	test::aa2::qqq::aas = 2;
	test::aa2::qqq::aas = test::aa2::qqq::bla * 33;
	test::aa2::qqq::blastring = "test";
	ttt = test::aa2::qqq::bla2;
	bla = test::aa2::qqq::aas;
	bla++;
	bla++;
	bla4343();
	fkd = set_aaaa(2);
	{
		int fdsfsd = 342;
	}
	return 0;
}
