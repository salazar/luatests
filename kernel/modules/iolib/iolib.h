#ifndef _IOLIB_H
#define _IOLIB_H

int kclose(int);
int kopen(const char*, int, int, int*);
int kwrite(int, void*, size_t, size_t*);
int kread(int, void*, size_t, size_t*);

file_t* kfopen(const char*, const char*, int*);
file_t* kfdopen(int fd);

char kgetc(int fd);

int kremove(const char*);

#endif
