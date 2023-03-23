import numpy as np

def rosenbrock(params):
    x = params['cv']     # continuous variables
    ASV = params['asv']  # active set vector (ASV)

    f0 = x[1] - x[0]*x[0]
    f1 = 1 - x[0]

    retval = dict([])

    if (ASV[0] & 1): # **** f:
        f = np.array([100*f0*f0+f1*f1])
        retval['fns'] = f
    return(retval)
