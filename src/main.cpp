#include <ctime>
#include <iostream>
#include <cstdlib>
#include <stdlib.h>
#include <string.h>
#include <strings.h>
#include <unistd.h>
#include <cstdio>
#include <memory>
#include <array>



std::string exec(const char* cmd){
		
	std::array<char, 128>buffer;
	std::string res;
	std::unique_ptr<FILE, decltype(&pclose)> pipe(popen(cmd, "r"), pclose);
	if (!pipe){
		throw std::runtime_error("popen() failed!");
	}
	while(fgets(buffer.data(), buffer.size(), pipe.get()) != nullptr){
		res += buffer.data();
	}

	return res;
}

std::string getFPT(){
	std::string fpt;
	return fpt;
}
int main(int argc, char *argv[]){
	
	char* ru_env_var = (char*)"USER";
	char* usr;
	usr = getenv(ru_env_var);

	// Here we need to read from /etc/sshRotate/rotate.conf

	// This should be in a struct gathered from the conf file
	char* env = (char*)"HOME";
	char* home = getenv(env);

	pid_t ppid;
	ppid = getppid();

	if (usr != nullptr){
		std::system("clear -x"); // clears 
		std::cout << "Your SSH key needs to be updated";
		
	std::cout << ppid << std::endl;
		usleep(5000);
		std::string fpt = getFPT();
		std::cout << fpt << std::endl;

	}

	return 0;
}
