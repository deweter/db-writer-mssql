#!/usr/bin/env bash

export MSSQL_DB_SSH_KEY_PRIVATE="-----BEGIN RSA PRIVATE KEY-----
MIIEogIBAAKCAQEAtrRqT7d6qyPxuEDiXj+5ANooQvVP3GONhjWbnnayqHDRhkAY
L4xjUT9ZAnsV3miduSlLYvrRWz41a3besYagC4sFLqUmBbrGgFRA3MJeiizBgDh1
g9F+4Xa2i98OAE8jUwb6MMnPWb7KJZTck1Kg1sTdlEk35PPV3fktp6AH6AlCXeHz
BJgXgAKpWE2oxxikimHERqJMXIu3cml6BxEILHdIImViGQEzVJFk1d+m05xozMc+
KSuixzYJUETTuBqcUCOQZonutIFXDiEAIZm606vW8HKC6ukhgTlDv1a+mZy3CPIe
FudB0jVHlyrRTHjTIMw4EvMeDsNFyxKY7o0RoQIDAQABAoIBAHSvDoJw3K/2Gcch
8TBeJAouSa5Ruzo2fkkrbYKrrfgzbSz/PDMJxtg5y9/wugu75pc9jz7cjt5mAXnr
hdf88bPNina61GiuW13T8UTMAdLfOIlqBWs1XYIi7fywbOG3qQi6mQiVqo5XcgTE
aIbSK5ReUGEGzeKz8297VzQJ2WLPiNhv4vz2dc0GRF/m7EnBLMm3ZF3xi87o6DE0
KhJdjnk4oSl+PWH4qD/QDBsLiswL/RyLxcITBQlxRCJGeflC8vWoFgFWLA3EgGUc
AVCPwHj9sjGKg8rurG3RyOAEGFxsmXr00K0e7kxxj9g4o/pdaFEE7ukL302gNZmG
3QofiW0CgYEA84rqFxC39r6KkUfkNZ4mfjTne77r3ye8UBTSPFmPFbnjnu7El25A
9+xuDyLoDqIglidXkGR9MsP58znPeYQ3j9uYDRIIjOVWiw0f5Zxmi2HsTGp/jABV
03WWQDq5H+c1htyp4b5sxYHSjJja/so3GX9z4UHsJ6kUIcniqjK9UnMCgYEAwAza
4ifRpuisrhKhXUihw+qTLreRRwHCOoBfT7F8SljYPDONX30kGTnJVtef58HhP9aW
hZpmgJ8wCibCyKv4QkHSX393MJjxOpDF26WXfLndd6Dc4edl7nly0Agixtj6qpHv
Jaw1J3c0/yfHGJopyBMQnoM1zKTYN3l/y+OLwpsCgYAkku4IvLgD1CWXH8bDzpZV
SbihutBNWPhMxnO0IHb+ekYWriDT5PjYwqbcmw9iczKVmh7qTk0G/KtivYHM6/A0
KHQzMkwabK6Mf1IU92Hm+LO13iB9c+dvtC72Qlte0SgWsrjIcAKBvrdR6fqpXNDd
gWhzoaTHZ/rgACOMD8aixQKBgDXdJSLbAi0rAwuLhCCSt3QofYFT0PY2YxBfYtwK
Lo73niY8W0FV6uL8VyD5NwscUJ3EBNGR/X/Dpgii2GzJ9sY2iddo+7fwnW/MnQG+
zt8Xjir4PhtJ+EfLXk1EiuR0hNGEPqu1Qe9Auud5c5jN3DwWRMoAiP1Nmqrsc9Bu
kItTAoGAMiE+r2tKFj2MMsg3YSHNTdn8HnYzc9itBIJxbM4Nz/LIZRCrDHd9tAQx
xUG0xkqnIeYYQxUeVoUik1D8/SiBxkPOSS/ApZbe1riEV7zCUNpsL61d7WFf+wXx
YdFA7sjJoFhItY1yEx90q8IBVAcBU4hRE7i/27kfnCImVc3mK1A=
-----END RSA PRIVATE KEY-----"

export MSSQL_DB_SSH_KEY_PUBLIC="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC2tGpPt3qrI/G4QOJeP7kA2ihC9U/cY42GNZuedrKocNGGQBgvjGNRP1kCexXeaJ25KUti+tFbPjVrdt6xhqALiwUupSYFusaAVEDcwl6KLMGAOHWD0X7hdraL3w4ATyNTBvowyc9ZvsollNyTUqDWxN2USTfk89Xd+S2noAfoCUJd4fMEmBeAAqlYTajHGKSKYcRGokxci7dyaXoHEQgsd0giZWIZATNUkWTV36bTnGjMxz4pK6LHNglQRNO4GpxQI5Bmie60gVcOIQAhmbrTq9bwcoLq6SGBOUO/Vr6ZnLcI8h4W50HSNUeXKtFMeNMgzDgS8x4Ow0XLEpjujRGh miroslavcillik@Miroslavs-MacBook-Air.local"

composer selfupdate
composer install -n

# wait for MSSQL container to start
export DOCKERIZE_VERSION="v0.3.0"
wget https://github.com/jwilder/dockerize/releases/download/$DOCKERIZE_VERSION/dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
    && tar -C /usr/local/bin -xzvf dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
    && rm dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz
dockerize -wait tcp://mssql:1433

sleep 20

./vendor/bin/phpstan analyse ./src ./tests --level=max --no-progress -c phpstan.neon \
  &&./vendor/bin/phpcs -n --ignore=vendor --extensions=php . \
  && ./vendor/bin/phpunit "$@"
