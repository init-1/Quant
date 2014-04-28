function ofts=cscorrwt(iftsA, iftsB, iftsWt)

ofts = cscorr(iftsA, iftsB, 'type', iftsWt);
