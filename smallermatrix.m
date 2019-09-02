import "selection.m": EntriesOfRootElement;
import "bbclassical.m": B, Evaluate2, BBType, BBField, BBStandardGenerators, 
  BBDimension, BBInverseGenerators;
import "elements.m": ConjugateClassicalStandardToMyBasis, RootElements, 
  DiagonalElement;

// The matrix of the standard orthogonal form of degree n and sign t over F -- 
// was an intrinsic 
  MyOrthogonalForm := function ( t, n, F)
   return IsOdd(Characteristic(F)) select
      SymmetricBilinearForm(t,n,F) else QuadraticForm(t,n,F);
end function;

/* 
  The orthogonal form preserved by the group generated by 
  ClassicalStandardGenerators is not always the same as the form whose
  Gram matrix is the output of OrthogonalForm. The following function
  returns the right Gram matrix.
*/
    
GramMatrixOfForm := function( type, dim, q )
    
    if type eq "SL" then 
        
        return Zero( MatrixAlgebra( GF( q ), dim ));
       
    elif type eq "Sp" then
        
        return StandardAlternatingForm( dim, q );
        
    elif type eq "SU" and IsEven( dim ) then
        
        return StandardHermitianForm( dim, Round( Sqrt( q )));
        
    elif type eq "SU" and IsOdd( dim ) then
        
        list :=  [1..dim div 2] cat [dim div 2 +2..dim] cat [ dim div 2 + 1 ];
        perm := PermutationMatrix( GF( q ), Sym( dim )!list );

        return perm*StandardHermitianForm( dim, 
                       Round( Sqrt( q )))*perm^-1;
    
    elif type eq "Omega+" then
        
        return case< IsEven( q ) | 
               true: QuadraticForm( 1, dim, GF( q )),
               default : MyOrthogonalForm( 1, dim, GF( q ))>;
                
    elif type eq "Omega-" then
        
        stgens := ClassicalStandardGenerators( "Omega-", dim, q );
        stgroup := sub< GL( dim, q ) | stgens >;
        
        if IsEven( q ) then
            _, form := QuadraticForm( stgroup );
        else
            _, _, form := OrthogonalForm( stgroup );
        end if;
        
        conj := ConjugateClassicalStandardToMyBasis( "Omega-", dim, q );
        
        return conj^-1*form*conj;
        
    elif type eq "Omega" then
        
        el := Integers()!((q-1)/2 );
        formmat := Zero( MatrixAlgebra( GF( q ), dim ));
        formmat[dim,dim] := el;
        for i in [1..dim-1] do
            formmat[i,dim-i] := 1;
        end for;    
        
        return formmat;
    end if;
end function;

// ClassicalStandardForm returns the form preserved
// by ClassicalStandardGenerators.

ClassicalStandardForm := function( type, dim, q )

  conj := ConjugateClassicalStandardToMyBasis( type, dim, q );
  return conj*GramMatrixOfForm( type, dim, q )*conj^-1;

end function;

/* 
   vec1 and vec2 are elements of a vector space with non-degenerate 
   sesquilinear form given by type, dim, and q. We calculate the value of 
   (vec1,vec2). 
*/
    
ScalarOfForm := function( type, dim, q, vec1, vec2 )
  
    // no form is preserved by SL and so we return 1
    
    if type eq "SL" then
        
        return 1;
        
    else 
        
        gr := GramMatrixOfForm( type, dim, q );
        
        if type eq "SU" then
            q0 := Round( Sqrt( q ));
            vec2 := [ vec2[i]^q0 : i in [1..dim] ];
        else
            vec2 := [ vec2[i] : i in [1..dim] ];
        end if;
        
        vec2tr := ColumnMatrix( vec2 );
        el := vec1*gr*vec2tr;
        return el[1];
    end if;
    
end function;
    
  /* 
  In orthogonal groups we also have to make sure that Spinor
  norm of SmallerMatrix is 0 before using the recursive step.
  */
      
MakeSpinorNormZero := function( G, mat )

    type := BBType( G );
    
    if not type in { "Omega", "Omega+", "Omega-" } then 
        return mat, One( B );
    end if;
    
    // first construct the Gram matrix of the form
      
    F := BBField( G ); dim := BBDimension( G );  
    q := #F;  
    
    sign := case< type | "Omega-": -1, default: 1 >;
    formmat := GramMatrixOfForm( type, dim, q );
    
    sp := SpinorNorm( GL( dim, F )!mat, formmat );
    
    if sp eq 0 then 
        return mat, One( B ); 
    else
        // of non-zero, return the negative of mat
        return -mat, One( B );
    end if;
    
end function;

     
/* 
  The following function takes the group G and an element g in G that
  preserves the subspace <e_1> and determines the preimage of g in 
  SX(type,dim,q) as a matrix. Then it writes this matrix as an SLP, 
  completing, in most cases, the rewriting process.
*/

SmallerMatrix := function( G, g : Method := Method )

    F := BBField( G );
    q := #F;
    dim := BBDimension( G );
    type := BBType( G );
        
    if <type,dim,Method>  eq <"SL",2,"BB"> or 
       <type,dim,Method> eq <"SU",3,"BB"> or
       <type,dim,Method> eq <"SU",4,"BB"> then 
        return One( B ), One( B ), g^0;
    end if;
    
    /* 
      get the elements T_{f1,b} where b is an element of the basis
      In the case of SU this returns T_{f1,alpha f_i} where
      alpha = gamma^{(q+1)/2} (gamma is primitive root). 
      This will be rectified later.
    */
        
    roots := RootElements( G );

    // start the matrix with [1,0,...,0] in the first row
    mat := [ One( F ) ] cat [ 0 : i in [ 1..dim-1]];
    
    wittindex := case< type | "SL": dim, "Omega-": Round( dim/2-1 ), 
                 default: Floor( dim/2 )>;
    wittdefect := dim-2*wittindex;
    
    if type eq "SU" then
        q0 := Round( Sqrt( #F ));
    end if;
    
    for r in roots do 

        vec := [ 0 ] cat 
               EntriesOfRootElement( G, r^g : Method := Method, 
                       GetWE1Entry := BBType( G ) eq "SU" and 
                       IsOdd( BBDimension( G ) ));
        // insert one more zero
          
        if type ne "SL" then  
            Insert( ~vec, dim-wittdefect, 0 );
        end if;
        mat := mat cat vec;
    end for;
    
    // insert the last row of the matrix
    
    if type ne "SL" then
        for i in [1..dim] do
            Insert( ~mat, #mat-wittdefect*dim+1, case< i | 
                    dim-wittdefect: 1, default: 0 >);
        end for;
    end if;

    mat := MatrixAlgebra( F, dim )!mat;
    
    /*
      now we fix the problem of having T_{f1,alpha f_i} instead of 
      T_{f1,f_i} in SU in odd char
    */             

    if BBType( G ) eq "SU" and IsOdd( #F ) then
               
        for i in [ Floor( dim/2 )+1..dim-1-wittdefect] do
            mat[i] := mat[i]*PrimitiveElement( F )^-Round((q0+1)/2);
        end for;
    end if;
    
    if type eq "SL" then
        
        /* the determinant of this matrix may not be one, but it is 
           a dim-th root.
           we make determinant 1. */
      
        roots := AllRoots( Determinant( mat ), dim );
        if #roots eq 0 then return false, false, false; end if;
          
        detroot := Representative( roots );  
        for i in [1..dim] do
            mat[i] := detroot^-1*mat[i];
        end for;
        
    elif type eq "Sp" then

        sc := ScalarOfForm( type, dim, #F, mat[2], mat[dim-1] ); 
        if not IsSquare( sc ) then
            return false, false, false;
        end if;
       
        sc := SquareRoot( sc );
        mat[1] := sc^-1*mat[1];
        
        for i in [2..dim-1] do
            mat[i] := sc^-1*mat[i];
        end for;
        
        mat[dim] := sc*mat[dim];

    elif type eq "SU" then
        
        if IsEven( dim ) then
            vec1 := mat[2]; vec2 := mat[dim-1];
        else
            vec1 := mat[dim]; vec2 := mat[dim];
        end if;
                   
        sc := ScalarOfForm( type, dim, #F, vec1, vec2 ); 
        det := Determinant( mat );
        
        if not exists(a){ r : r in  AllRoots( (sc*det)^-1, dim ) |
                   r^(-q0-1) eq sc and r^(q0-dim+1) eq det } 
           then return false, false, false;
        end if;
       
        mat[1] := a*mat[1];
        for i in [2..dim-1-wittdefect] do
            mat[i] := a*mat[i];
        end for;
        
        mat[dim-wittdefect] := a^(-q0)*mat[dim-wittdefect];
        
        if IsOdd( dim ) then
            mat[dim] := a*mat[dim];
        end if;
        
    elif type in { "Omega+", "Omega", "Omega-" } then
        
        if type eq "Omega" and dim eq 3 then
            vec1 := mat[dim]; vec2 := mat[dim];
        elif type eq "Omega-" and IsOdd( q ) then 
            vec1 := mat[dim-1]; vec2 := (-1/2)*mat[dim-1];
        elif type eq "Omega-" and IsEven( q ) then
            zz := PrimitiveElement( GF( q ));
            vec1 := mat[dim]; vec2 := zz^-1*mat[dim];
        elif IsOdd( #F ) then
            vec1 := mat[2]; vec2 := mat[dim-1-wittdefect]; 
        else
            vec1 := mat[2]+mat[dim-1-wittdefect];
            vec2 := mat[2]+mat[dim-1-wittdefect];
        end if;
        
        sc := ScalarOfForm( type, dim, #F, vec1, vec2 );
        if type eq "Omega" and dim eq 3 then
           sc := sc/Integers()!((#F-1)/2 );
        end if;
       
        sc := SquareRoot( sc );
        if sc^(-dim+2)*Determinant( mat ) eq -1 then  
            sc := -sc;
        end if;
        
        mat[1] := sc^-1*mat[1];
        
        for i in [2..dim-1-wittdefect] do
            mat[i] := sc^-1*mat[i];
        end for;
        
        mat[dim-wittdefect] := sc*mat[dim-wittdefect];
        
        if type eq "Omega" then
            mat[dim] := sc^-1*mat[dim];
        end if;

        if type in { "Omega-" } then
            mat[dim-1] := sc^-1*mat[dim-1];
            mat[dim] := sc^-1*mat[dim];
        end if;
        
    end if;
    
    if Dimension( Parent( mat )) le 1 then 
        return One( B ), One( B ), One( G );
    end if;

    mat, prs := MakeSpinorNormZero( G, mat );

    mat := GL( dim, q )!mat;
    q0 := case< type | "SU": Round( Sqrt( q )), default: q >;
    stgens := ClassicalStandardGenerators( type, dim, q0 );

    conj := ConjugateClassicalStandardToMyBasis( type, dim, q )^-1;
    
    mat := conj^-1*mat*conj; 
    stgroup := sub< GL( dim, q ) | stgens >;
    _, pr5 := ClassicalRewriteNatural( type, mat^0, mat );

    pr5 := Evaluate2( pr5, BBInverseGenerators( G ));
    g0 := Evaluate( pr5, BBStandardGenerators( G ));

    /* if g0 is not equal to g, then we try to modify it with a 
       diagonal element */
    
    if g0 ne g then 
        
        // flag to see if found the right element modulo center
        foundcentral := false;
        gens := Generators( G );
        // quick function to check if an element is central
        iscentral := func< x | { true } eq { x^z eq x : z in gens } >;
        // create the diagonal element    
        pd := DiagonalElement( type, dim, q0 );
        d := Evaluate( pd, G`StandardGenerators ); 
        assert iscentral( d );

        exp := 1; 
        maxtry := case< type | 
                  "SL": GCD( dim, q-1 ), 
                  "SU": GCD( q0+1, dim ),
                  "Sp": 2,
                  default: 2 >;
        assert maxtry ge Order( d ); 
        repeat
            
            if not foundcentral and iscentral( g*g0^-1 ) then;
                foundcentral := true;
                cpr := pr5*pd^(exp-1); 
            end if;
            
            g0 := g0*d;
            exp := exp+1;

        until g0 eq g or exp ge maxtry;
        
        if g0 ne g and foundcentral then
            return cpr, prs, Evaluate( prs, BBStandardGenerators( G ));
        end if;
        
        if g0 ne g then
            return false, false, false;
        end if;
        
        pr5 := pr5*pd^(exp-1); 
    end if;
    
    return pr5, prs, Evaluate( prs, BBStandardGenerators( G ));
end function;
