Rewriting in black box classical groups
Intrinsic 'ClassicalRewrite'

Contains the Magma implementation of several algorithms that write an element of a classical group as an SLP in the standard
generators.

Signatures:

    (G::Grp, gens::SeqEnum, type::MonStgElt, dim::RngIntElt, q::RngIntElt, 
    g::GrpElt) -> BoolElt, GrpElt
    [
        Method
    ]

        The group G must be isomorphic to the classical group given by the 
        argument type, dim, and q; gens must be a generating set of G that 
        satisfies ClassicalStandardPresentation( type, dim, q ); g must be an 
        element in the same universe as the generators of G; the string type is 
        one of "SL", "Sp", "SU", "Omega", "Omega+", "Omega-". The function 
        checks if g is an element of G and returns true or false accordingly. 
        Further, if g is in G, then the function also returns a straight-line 
        program from gens to g. The algorithm employed in the function depends 
        on whether G is given in its natural representation, in a matrix 
        representation over a field in the defining characteristic (grey-box), 
        or in some other representation that that does not fall under the 
        previous cases (black-box). The optional parameter Method may be 
        supplied to override the default choice of algorithm. The possible 
        values of Method are "BB" (to force that the black-box algorithm be 
        used) or "CharP" (to force the grey-box algorithm). If g is not an 
        element of G, then the program attempts to find an SLP that points to an
        element of h such that gh^-1 centralises G. If such an SLP is found that
        the function returns false and this SLP.

