#include <stdio.h>
#include <string>
#include <map>

typedef std::map<std::string, std::string> stringmap;

int main(void)
{
	int state = 0;
	int c;
	std::string name, var;
	stringmap vars;

	while ((c = getchar()) != EOF) {
		if (c == '\r')
			continue;
		switch (state) {
		case 0:
			if (c == '\n')
				name = "";
			else if (c == 0xad) {
				getchar();
				goto nextfile;
			} else if (c != '=')
				name += c;
			else {
				var = "";
				state = 1;
			}
			break;
		case 1:
			if (c != '\n')
				var += c;
			else {
				state = 0;
				vars[name] = var;
				name = "";
			}
		}
	}

nextfile:
	int ending;
	while ((c = getchar()) != EOF) {
		if (c == '\r')
			continue;
		switch (state) {
		case 0:
			if (c == '$')
				state = 1;
			else
				putchar(c);
			break;
		case 1:
			if (c == '{' || c == '(') {
				name = "";
				state = 2;
				ending = c == '{' ? '}' : ')';
			} else {
				putchar('$');
				putchar(c);
				state = 0;
			}
			break;
		case 2:
			if (c != ending)
				name += c;
			else {
				if (vars.count(name) == 0) {
					fprintf(stderr, "%s not found in defined variables\n", name.c_str());
					return 2;
				} else
					printf("%s", vars[name].c_str());
				state = 0;
			}
			break;
		}
	}
	return 0;
}
