# busybox uclibc - staic compile clib
FROM --platform=linux/amd64 busybox:uclibc AS build-env
RUN mkdir tfekscode-bin
RUN cd tfekscode-bin
WORKDIR /tfekscode-bin
ADD terraform-eks-code/bin /tfekscode-bin
#scratch - needs dummy executable to at least return nothing
#FROM scratch 
#WORKDIR /
#COPY --from=build-env /tfekscode /tfekscode
