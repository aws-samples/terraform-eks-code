# busybox uclibc - staic compile clib
FROM busybox:uclibc AS build-env
RUN mkdir tfekscode 
RUN cd tfekscode
WORKDIR /tfekscode
RUN mkdir bin
ADD terraform-eks-code /tfekscode
#WORKDIR /
#FROM scratch 
#WORKDIR /
#COPY --from=build-env /tfekscode /tfekscode
