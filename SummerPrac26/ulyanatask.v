Require Import Coq.Lists.List.
Require Import Coq.Arith.Arith Lia.
Import ListNotations.

Inductive Sigma : Type := A | B.
Definition word := list Sigma.

Fixpoint pow (k:nat) (w:word) : word :=
    match k with
    | 0   => []
    | S k => w ++ pow k w
    end.

Lemma pow_app : forall m n (w : word),
    pow (m + n) w = pow m w ++ pow n w.
Proof.
    induction m as [|m' IH]; intros n w. 
  - (* База: m = 0 *)
    simpl.                (* pow 0 w = [] *)
    reflexivity.
  - (* Шаг: m = S m' *)
    simpl.                (* pow (S m') w = w ++ pow m' w *)
    rewrite IH.        
    rewrite app_assoc.    
    reflexivity.
Qed.

Lemma app_equidivisible:
  forall (l1 l2 l3 l4 : word),
    l1 ++ l2 = l3 ++ l4 ->
    exists s,
         (l1 = l3 ++ s /\ l4 = s ++ l2)
      \/ (l3 = l1 ++ s /\ l2 = s ++ l4).
Proof.
  intros l3 l4.
  induction l3 as [|a l3 IH]; intros l1 l2 H.
  - (* База: l3 = [] *)
    simpl in H.                    
    exists l1.
    right. split.
    + simpl. reflexivity.         
    + rewrite H. reflexivity.       (* l4 = l1 ++ l2 *)

  - (* Шаг: l3 = a :: l3 *)
    destruct l1 as [|b l1].
    + (* l1 = [] *)
      simpl in H.                  
      exists (a :: l3).
      left. split.           
      * simpl. reflexivity.           
      * simpl. rewrite H. reflexivity.
    + (* l1 = b :: l1 *)
      simpl in H.       
      inversion H.
      subst.

      (* Применяем ИП к равенству хвостов l3 ++ l4 =  l1 ++ l2 *)
      destruct (IH _ _ H2) as [s [[Hs1 Hs2] | [Hs1 Hs2]]].
      * (* l3 = l1 ++ s  и  l2 = s ++ l4 *) 
        exists s. 
        left. split.
        -- simpl. rewrite Hs1. reflexivity.  
        -- exact Hs2.
      * (* l1 = l3 ++ s  и  l4 = s ++ l2 *)
        exists s. 
        right. split.
        -- simpl. rewrite Hs1. reflexivity. 
        -- exact Hs2.
Qed.


Lemma commute_powers_aux :
  forall n,
    (forall x y : word,
        length x + length y = n ->
        x ++ y = y ++ x ->
        exists (omega : word) (k1 k2 : nat),
          x = pow k1 omega /\ y = pow k2 omega).
Proof.
  (* Индукция по n с предикатом P n := ... *)
  eapply (well_founded_induction
            lt_wf
            (fun n =>
               forall x y,
                 length x + length y = n ->
                 x ++ y = y ++ x ->
                 exists w k1 k2, x = pow k1 w /\ y = pow k2 w)).
  intros n IH x y Hlen Heq.

  (* Базовые случаи: одно из слов пустое *)
  destruct x as [|a x'].
  exists y, 0, 1; simpl; auto.          (* w = y, k1 = 0, k2 = 1 *)
  destruct y as [|b y'].
  exists (a::x'), 1, 0; simpl; auto.    (* w  = a::x', k1 = 1, k2 = 0 *)
    

  (* Оба непустые *)
  (* Упростим Hlen: |x| = S|x'|, |y| = S|y'| *)
  simpl in Hlen.                     (* S(|x'|) + S(|y'|) = n *)

  (* Разложим равенство конкатенаций *)
  destruct (app_equidivisible _ _ _ _ Heq) as [t [[Hx Hy] | [Hyx Hx']]].

  - (* x = y ++ t,  y = t ++ y *)
    (* Коммутативность t и y *)
    (* Hx: a::x' = (b::y') ++ t ;  Hy: a::x' = t ++ (b::y') *)
    assert (Hcomm : t ++ (b :: y') = (b :: y') ++ t).
    rewrite <- Hy. exact Hx.
    (* Равенство длин из Hx: S|x'| = S|y'| + |t| *)
    assert (Hlen_x : S (length x') = S (length y') + length t).
    apply (f_equal (@length Sigma)) in Hx.
    simpl in Hx. rewrite app_length in Hx. exact Hx.

    (* Уменьшение меры: |t| + S|y'| < n = S|x'| + S|y'| *)
    assert (Hlt : length t + S (length y') < n) by lia.

    (* Применяем ИГ к паре (t, b::y') *)
    specialize (IH _ Hlt t (b::y') ltac:(reflexivity) Hcomm) as [w [k1 [k2 [Ht Hy2]]]].

    (* x = y ++ t = w^(k2) ++ w^(k1) = w^(k2+k1) *)
    exists w, (k2 + k1), k2.
    split.
    + (* x = w^(k2+k1) *)
      rewrite Hx.                    (* x = y ++ t *)
      rewrite Hy2.                   (* y = w^k2 *)
      rewrite Ht.                    (* t = w^k1 *)
      rewrite pow_app.               
      reflexivity.
    + (* y = w^k2 *)
      exact Hy2.

  - (* y = x ++ t,  x = t ++ x *)
    (* Коммутативность t и x *)
    (* Hyx: b::y' = (a::x') ++ t ;  Hx': b::y' = t ++ (a::x') *)
    assert (Hcomm : t ++ (a :: x') = (a :: x') ++ t).
    rewrite <- Hx'. exact Hyx. 
    (* Равенство длин из Hyx: S|y'| = S|x'| + |t| *)
    assert (Hlen_y : S (length y') = S (length x') + length t).
    apply (f_equal (@length Sigma)) in Hyx.
    simpl in Hyx. rewrite app_length in Hyx. exact Hyx. 
    (* Уменьшение меры: |t| + S|x'| < n *)
    assert (Hlt : length t + S (length x') < n) by lia.

    (* Применяем ИГ к паре (t, a::x') *)
    specialize (IH _ Hlt t (a::x') ltac:(reflexivity) Hcomm) as [w [k1 [k2 [Ht Hx2]]]].

    (* x = w^k2,  y = w^(k2+k1) *)
    exists w, k2, (k2 + k1).
    split.
    + (* x = w^k2 *)
      exact Hx2.
    + (* y = x ++ t = w^k2 ++ w^k1 = w^(k2+k1) *)
      rewrite Hyx, Hx2, Ht, pow_app; reflexivity.
Qed.


Theorem commute_powers :
  forall (x y : word),
    x ++ y = y ++ x ->
    exists (omega : word) (k1 k2 : nat),
      x = pow k1 omega /\ y = pow k2 omega.
Proof.
  intros x y Heq.
  (* Подставляем меру n = |x| + |y| в commute_powers_aux *)
  eapply commute_powers_aux with (n := length x + length y); eauto.
Qed.