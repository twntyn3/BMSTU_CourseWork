
From Stdlib Require Import Arith.
Require Import Lia.

Inductive list (X : Type):=
| nil : list X
| cons : X -> list X -> list X.

Check nil.
Check cons.

Arguments nil {X}.

Arguments cons {X}.

Check cons 3 (cons 5 (cons 1 (nil))).


Notation "[]" := nil.
Notation "x :: xs" := (cons x xs).

Check (3 :: 5 :: 1 :: []).

Notation "[ x ; .. ; y ]" :=
    (cons x .. (cons y nil) ..).

Check [1; 2; 3].

Check [true; false; false].


Fixpoint length {X : Type} (xs : list X) : nat :=
    match xs with
    | [] => 0
    |  x :: xs' => S (length xs')
    end.

Fixpoint append {X : Type} (xs ys : list X) : list X :=
    match xs with
    | [] => ys
    | x :: xs' => x :: append xs' ys
    end.

Notation "xs ++ ys" := (append xs ys).

Lemma length_app :
    forall ( X : Type) (xs ys : list X),
    length ( xs ++ ys ) = length xs + length ys.
Proof.
    intros X xs ys.
    induction xs.
     - reflexivity.
     - simpl. apply f_equal. assumption.
Qed.

Fixpoint insert (a : nat) (xs :list nat) : list nat :=
    match xs with
    | [] => [a]
    | x :: xs' =>
        if a <=? x then
             a :: x :: xs'
        else 
            x :: insert a  xs'
end.

Fixpoint sort (xs : list nat) :=
    match xs with
    | [] => []
    | x :: xs' => insert x (sort xs')
    end.
    Compute (sort [3; 5; 1; 0; 6]).


    Inductive sorted : list nat -> Prop :=
    | sorted_nil : sorted []
    | sorted_single : forall x, sorted [x]
    | sorted_cons :
        forall a b bs,
        a <= b ->
        sorted (b :: bs) ->
        sorted (a :: b :: bs).
    
    
    Lemma sorted_sort :
        forall xs, sorted (sort xs).
    Proof.
        intros xs. induction xs.
        - simpl. apply sorted_nil.
        - simpl.
    Abort.
    
    Search "<=?" "<=".
    
    

    Lemma sorted_insert :
        forall x xs,
        sorted xs -> sorted (insert x xs).
    Proof.
        intros x xs H.
        induction H.
        - simpl. apply sorted_single.
        - simpl. destruct (x <=? x0) eqn:Hx.
            + apply sorted_cons.
                * apply Nat.leb_le in Hx. assumption.
                * constructor.   
            + constructor.
                * apply Nat.leb_nle in Hx. lia.
                * apply sorted_single.
         - simpl. destruct (x <=? a) eqn:Hx.
         + apply sorted_cons.
         * apply Nat.leb_le in Hx. assumption.
         * apply sorted_cons.
           -- assumption.
           -- assumption.
       + simpl in IHsorted.
         destruct (x <=? b) eqn:Hy.
         * apply sorted_cons.
           -- apply Nat.leb_nle in Hx. lia.
           -- apply sorted_cons.
              ++ apply Nat.leb_le in Hy.
                 assumption.
              ++ assumption.
         * apply sorted_cons.
           -- assumption.
           -- assumption.
   
   Qed.


   Inductive Permutation : list nat -> list nat -> Prop :=

   | Permutation_nil :
 
       Permutation [] []
 
   | Permutation_skip :
 
       forall x l1 l2,
 
         Permutation l1 l2 ->
 
         Permutation (x :: l1) (x :: l2)
 
   | Permutation_swap :
 
       forall x y l,
 
         Permutation (y :: x :: l) (x :: y :: l)
 
   | Permutation_trans :
 
       forall l1 l2 l3,
 
         Permutation l1 l2 ->
 
         Permutation l2 l3 ->
 
         Permutation l1 l3.

Lemma Permutation_sort :
   forall xs, Permutation xs (sort xs).
   Proof.
   Abort.





   
   (*
   можно сократить используя ";" при повторении операций
   также можно использовать auto (обращается к базе утверждений, которые по умолчании добавлены к стандартной библиотеке, также мы можем ранее доказанные утверждения добавить к базе)

   Hint Constructed : sorted core.
   
   
   
   
   
   *)


   
