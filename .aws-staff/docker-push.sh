docker image rm tfekscode
typ=$(uname -s)
if [[ $typ == "Linux" ]]; then
    cd ~/environment
    cp tfekscode/bin/Dockerfile .
fi
docker build . -t tfekscode --platform amd64
docker tag tfekscode:latest public.ecr.aws/awsandy/tfekscode
docker push public.ecr.aws/awsandy/tfekscode
