#!/bin/bash

function init_packages {
    JULIA_VER=$1
    /opt/julia-${JULIA_VER}/bin/julia -e "Pkg.init()"
}

function include_packages {
    JULIA_VER=$1
    PKG_LIST=$2
    METHOD=$3
    for PKG in $PKG_LIST
    do
        echo ""
        echo "$METHOD package $PKG to Julia $JULIA_VER ..."
        /opt/julia-${JULIA_VER}/bin/julia -e "Pkg.${METHOD}(\"$PKG\")"
        if [ ${METHOD} == "add" ]
        then
            /opt/julia-${JULIA_VER}/bin/julia -e "Pkg.build(\"$PKG\")"
        fi
    done
}

function list_packages {
    JULIA_VER=$1
    echo ""
    echo "Listing packages for Julia $JULIA_VER ..."
    /opt/julia-${JULIA_VER}/bin/julia -e 'println("JULIA_HOME: $JULIA_HOME\n"); versioninfo(); println(""); Pkg.status()' > /opt/julia_packages/julia-${JULIA_VER}.packages.txt
}

# Install packages for Julia 0.3
DEFAULT_PACKAGES="IJulia JuliaWebAPI PyPlot Interact Colors SymPy PyCall"
INTERNAL_PACKAGES="https://github.com/tanmaykm/JuliaBoxUtils.jl.git \
https://github.com/shashi/Homework.jl.git"
BUILD_PACKAGES="JuliaBoxUtils IJulia PyPlot"

init_packages "0.3"
include_packages "0.3" "$DEFAULT_PACKAGES" "add"
include_packages "0.3" "$INTERNAL_PACKAGES" "clone"
include_packages "0.3" "$BUILD_PACKAGES" "build"
list_packages "0.3"


# Install packages for Julia 0.4
DEFAULT_PACKAGES="IJulia JuliaWebAPI Requests DistributedArrays PyPlot Interact Colors SymPy PyCall"
INTERNAL_PACKAGES="https://github.com/tanmaykm/JuliaBoxUtils.jl.git \
https://github.com/shashi/Homework.jl.git \
https://github.com/Keno/Docker.jl \
https://github.com/gsd-ufal/Infra.jl"
BUILD_PACKAGES="JuliaBoxUtils IJulia PyPlot"

init_packages "0.4"
include_packages "0.4" "$DEFAULT_PACKAGES" "add"
include_packages "0.4" "$INTERNAL_PACKAGES" "clone"
include_packages "0.4" "$BUILD_PACKAGES" "build"
list_packages "0.4"
