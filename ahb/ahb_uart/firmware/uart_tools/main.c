#include <stdio.h>
#include <string.h>
#include "serial.h"
#include <unistd.h>

typedef unsigned int uint;
typedef unsigned char uchar;

int main(void)
{
    char buffer[50] = {0};

    printf("Please Enter Serial Port. For example: /dev/ttyUSB0\n");
    scanf("%s", buffer);
    if(openSerial(buffer) == OPEN_FAIL)
    {
        printf("Open Serial Port Fail!\n");
        return 0;
    }
    else
    {
        printf("Open Serial Port ==> OK!\n");
    }

    char fileName[100];
    unsigned char fileBuff[128];

    printf("Please Enter bin File Path, for exampl: ./firmware.bin \n");
    scanf("%s", fileName);

    FILE *file = fopen(fileName,"rb");
    if(file == 0)
    {
        printf("File Open Error!\n");
        return 0;
    }
    else
    {
        printf("Open file ==> OK!\n");
    }

    char flag;
    unsigned char length = 0;

    while(!feof(file))
    {
        memset(fileBuff, 0, sizeof(fileBuff) );
        length = fread(fileBuff, sizeof(unsigned char), sizeof(fileBuff), file);
        if(length > 0)
        {
            printf("transfer the data to the target, length = %d \r\n",length );
            serialSendChar('s');
            serialSendChar((unsigned char)length);
            serialSendStr((char *)fileBuff,length);

            serialReadChar(&flag);
            if(flag == 'n')
            {
                printf("Receive OK\n");
            }
            else
            {
                printf("Unknown Error!\n Flash Failed!\n");
                break;
            }
        }
    }

    serialSendChar('f');
    serialReadChar(&flag);
    if(flag == 'n')
    {
        printf("Download Success!\n");
    }

    closeSerial();

    return 0;
}
