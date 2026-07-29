Require Import Coq.Lists.List.

Require Import Coq.Arith.Arith.

Require Import Lia.

Import ListNotations.






Inductive Sigma : Type := 
| A
| B.

Definition word := list Sigma.
(*
Check A.
Check B.
Check [A; B; A].
Check ([] : word).

пока просто задаю два символа и слово, ничего 
не происходит вообще в программе

*)



Lemma levi :

  forall x y z t : word,

    x ++ y = z ++ t ->

    exists s : word,

      (x = z ++ s /\ t = s ++ y) \/

      (z = x ++ s /\ y = s ++ t).

Proof.

Admitted.

Check app_length.     

Definition block (w1 : word) (c : Sigma) (w2 : word) : word := 
    w1 ++ [c] ++ w2.

Goal forall w1 w2 w3 w4 : word,
    block w1 A w2 ++ block w1 B w2 =
    block w3 A w4 ++ block w3 B w4 ->
    w1 = w3 /\ w2 = w4.
(*

    Proof.
    intros w1 w2 w3 w4 H.
    unfold block in H.

    apply (f_equal (@length Sigma)) in H.

    repeat rewrite length_app in H.

    simpl in H.


Abort.

*)

Proof.
    intros w1 w2 w3 w4 H.

    pose proof H as Hlen.

    unfold block in Hlen.

    apply (f_equal (@length Sigma)) in Hlen.

    repeat rewrite length_app in Hlen.
    simpl in Hlen.

    assert(Hlen_block :

    length w1 + 1 + length w2 =

    length w3 + 1 + length w4).

    



    

Abort.


