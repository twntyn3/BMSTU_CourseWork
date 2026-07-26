Check Type.
Check true.
Check 1.
Check bool.
Check false.


Inductive bool :=
| true : bool
| false : bool.

Definition negb(b : bool) : bool :=
  match b with
  | true => false
  | false => true 
  end.

Definition andb (b1 b2 : bool) : bool:=
  match b1 with
  | true => b2
  | false => false
  end.
  
Compute (andb true false).

Lemma negb_inv :
  forall b, negb (negb b) = b.
Proof.
  intros b. destruct b.
  - simpl. reflexivity.
  - reflexivity.
Qed.

Lemma andb_com :
  forall b1 b2, andb b2 b1 = andb b1 b2.
Proof.
  intros b1 b2. 

  destruct b1, b2; reflexivity.
Qed.


Fixpoint addn (n m : nat) : nat :=
  match n with
    | 0 => m
    | S n' => S (addn n' m)
    end.

Notation "n + m" := (addn n m).

Lemma addn_id :
  forall n m, n = m -> n + n = m + m.
Proof.
  intros n m H.
  rewrite <- H.
  reflexivity.
Qed.

Lemma addl_0:
forall n, 0 + n = n.
Proof. reflexivity. Qed.

Lemma addr_0:
forall n, n + 0 = n.
Proof.
  intros n. induction n.
   - reflexivity.
   - simpl. rewrite IHn. reflexivity.




Qed.

Lemma addn_Sm :
  forall n m, S (n + m) = n + S m.
Proof.
  intros n m. induction n.
  - simpl. reflexivity.
  - simpl. rewrite IHn. reflexivity.
Qed.

Lemma addn_com :
  forall n m, n + m = m + n.
Proof




