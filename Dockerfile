FROM troox/openwrt-sdk:24.10.1

ARG PKG_VERSION
ENV PKG_VERSION=${PKG_VERSION}

COPY ./mbzeguard /builder/package/feeds/utilites/mbzeguard
COPY ./luci-app-mbzeguard /builder/package/feeds/luci/luci-app-mbzeguard

RUN make defconfig && make package/mbzeguard/compile && make package/luci-app-mbzeguard/compile V=s -j4