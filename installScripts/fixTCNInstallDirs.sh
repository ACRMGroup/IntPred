TCNDIR=packages/$1/lib
sed 's/{HOME}/{TCNlib}/g' ${TCNDIR}/TCNPerlVars.defaults >${TCNDIR}/foo
mv ${TCNDIR}/foo ${TCNDIR}/TCNPerlVars.defaults
