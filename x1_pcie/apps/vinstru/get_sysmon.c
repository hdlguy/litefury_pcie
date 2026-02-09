#include <stdio.h>
#include <stdint.h>
#include <unistd.h>
#include <stdlib.h>
#include <sys/mman.h>
#include <fcntl.h>
#include <string.h>

float read_temp()
{
    FILE* fd_iio = fopen("/sys/class/thermal/thermal_zone0/temp", "r");

    char iio_str[256];
    fscanf(fd_iio, "%s", iio_str);
    fclose(fd_iio);
    int iio_int = atoi(iio_str);
    float temp = (float)iio_int/1000.0;
    return(temp);
}

float read_vccint()
{
    FILE* pp = popen("vcgencmd pmic_read_adc | grep VDD_CORE_V", "r");
    char buffer[256], fltstr[256];
    fgets(buffer, sizeof(buffer), pp);
    pclose(pp);

    char* token = strtok(buffer, " =");
    int whilecount = 0;
    while (token != NULL) {
        if (whilecount==2) strcpy(fltstr, token);
        token = strtok(NULL, "=V");
        whilecount++;
    }

    char *endptr;
    float vccint = strtof(fltstr, &endptr);
    
    return(vccint);
}


float read_vccaux()
{
    FILE* pp = popen("vcgencmd pmic_read_adc | grep 1V8_SYS_V", "r");
    char buffer[256], fltstr[256];
    fgets(buffer, sizeof(buffer), pp);
    pclose(pp);

    char* token = strtok(buffer, " =");
    int whilecount = 0;
    while (token != NULL) {
        if (whilecount==2) strcpy(fltstr, token);
        token = strtok(NULL, "=V");
        whilecount++;
    }

    char *endptr;
    float vccint = strtof(fltstr, &endptr);
    
    return(vccint);
}


int main(int argc,char** argv)
{

    if (argc != 2) {
        printf("Usage: ./get_sysmon [arg]\n\t arg: 1 = temperature, 2 = VccInt, 3 = VccAUX\n");
        return 0;
    }

    float temp = read_temp();
    float vccint = read_vccint();
    float vccaux = read_vccaux();

    int select = atoi(argv[1]);
    if (select == 1) fprintf(stdout, "%3.2f\n", temp);
    if (select == 2) fprintf(stdout, "%2.3f\n", vccint);
    if (select == 3) fprintf(stdout, "%2.3f\n", vccaux);

    return 0;
}

// vcgencmd pmic_read_adc | grep 1V8_SYS_V
// vcgencmd pmic_read_adc | grep VDD_CORE_V
// VDD_CORE_V volt(15)=0.75186740V

