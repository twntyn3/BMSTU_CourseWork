Require Import Coq.Lists.List.
Require Import Coq.Arith.Arith.
Require Import Lia.

Import ListNotations.


Inductive Sigma : Type :=
| A
| B.

Definition word := list Sigma.


(* Обычная лемма Леви для слов *)
Lemma LEVI :
  forall l1 l2 l3 l4 : word,
    l1 ++ l2 = l3 ++ l4 ->
    exists s : word,
      (l1 = l3 ++ s /\ l4 = s ++ l2)
      \/
      (l3 = l1 ++ s /\ l2 = s ++ l4).
Proof.
  intros l3 l4.
  induction l3 as [|a l3 IH]; intros l1 l2 H.

  - (* l3 = [] *)
    simpl in H.

    exists l1.
    right.
    split.

    + simpl.
      reflexivity.

    + rewrite H.
      reflexivity.

  - (* l3 = a :: l3 *)
    destruct l1 as [|b l1].

    + (* l1 = [] *)
      simpl in H.

      exists (a :: l3).
      left.
      split.

      * simpl.
        reflexivity.

      * simpl.
        rewrite H.
        reflexivity.

    + (* l1 = b :: l1 *)
      simpl in H.
      inversion H.
      subst.

      destruct (IH _ _ H2)
        as [s [[Hs1 Hs2] | [Hs1 Hs2]]].

      * exists s.
        left.
        split.

        -- simpl.
           rewrite Hs1.
           reflexivity.

        -- exact Hs2.

      * exists s.
        right.
        split.

        -- simpl.
           rewrite Hs1.
           reflexivity.

        -- exact Hs2.
Qed.


(* Если первые части имеют одинаковую длину,
   то одинаковое слово разрезано в одном и том же месте *)
Lemma app_split_equal_length :
  forall x1 x2 y1 y2 : word,
    length x1 = length y1 ->
    x1 ++ x2 = y1 ++ y2 ->
    x1 = y1 /\ x2 = y2.
Proof.
  intros x1 x2 y1 y2 Hlen H.

  destruct (LEVI x1 x2 y1 y2 H) as [s Hcases].
  destruct Hcases as [Hcase1 | Hcase2].

  - destruct Hcase1 as [Hx1 Hy2].

    pose proof Hx1 as Hxx.
    apply (f_equal (@length Sigma)) in Hxx.
    repeat rewrite app_length in Hxx.

    assert (Hs : length s = 0).
    {
      lia.
    }

    destruct s.

    + rewrite app_nil_r in Hx1.
      simpl in Hy2.
      symmetry in Hy2.

      split.

      * exact Hx1.
      * exact Hy2.

    + simpl in Hs.
      lia.

  - destruct Hcase2 as [Hy1 Hx2].

    pose proof Hy1 as Hyy.
    apply (f_equal (@length Sigma)) in Hyy.
    repeat rewrite app_length in Hyy.

    assert (Hs : length s = 0).
    {
      lia.
    }

    destruct s.

    + rewrite app_nil_r in Hy1.
      simpl in Hx2.
      symmetry in Hy1.

      split.

      * exact Hy1.
      * exact Hx2.

    + simpl in Hs.
      lia.
Qed.


(* Сокращение одинакового префикса *)
Lemma remove_same_prefix :
  forall x y z : word,
    x ++ y = x ++ z ->
    y = z.
Proof.
  intros x y z H.

  destruct (LEVI x y x z H) as [s Hcases].
  destruct Hcases as [Hcase1 | Hcase2].

  - destruct Hcase1 as [Hx Hz].

    pose proof Hx as Hxx.
    apply (f_equal (@length Sigma)) in Hxx.
    repeat rewrite app_length in Hxx.

    assert (Hs : length s = 0).
    {
      lia.
    }

    destruct s.

    + simpl in Hz.
      symmetry in Hz.
      exact Hz.

    + simpl in Hs.
      lia.

  - destruct Hcase2 as [Hx Hz].

    pose proof Hx as Hxx.
    apply (f_equal (@length Sigma)) in Hxx.
    repeat rewrite app_length in Hxx.

    assert (Hs : length s = 0).
    {
      lia.
    }

    destruct s.

    + simpl in Hz.
      exact Hz.

    + simpl in Hs.
      lia.
Qed.


(* Ключевая модификация Леви.

   Если одни и те же слова окружают сначала A, а затем B,
   то левые и правые части однозначно определены. *)
Lemma two_markers_unique :
  forall x y u v : word,
    x ++ [A] ++ y = u ++ [A] ++ v ->
    x ++ [B] ++ y = u ++ [B] ++ v ->
    x = u /\ y = v.
Proof.
  intros x y u v HA HB.

  destruct
    (LEVI
       x ([A] ++ y)
       u ([A] ++ v)
       HA)
    as [s Hcases].

  destruct Hcases as [Hcase1 | Hcase2].

  - (* x = u ++ s *)
    destruct Hcase1 as [Hx Hv].

    (* Из второго равенства удаляем общий префикс u. *)
    rewrite Hx in HB.
    repeat rewrite <- app_assoc in HB.
    apply (remove_same_prefix u) in HB.

    destruct s as [|c s].

    + (* s = [] *)
      rewrite app_nil_r in Hx.
      rewrite app_nil_l in Hv.

      apply (remove_same_prefix [A]) in Hv.

      split.

      * exact Hx.

      * symmetry.
        exact Hv.

    + (* s непустой *)
      destruct c.

      * (* Первая буква s равна A.
           Но из равенства с B она должна быть B. *)
        simpl in HB.
        discriminate HB.

      * (* Первая буква s равна B.
           Но из равенства с A она должна быть A. *)
        simpl in Hv.
        discriminate Hv.

  - (* u = x ++ s *)
    destruct Hcase2 as [Hu Hy].

    (* Из второго равенства удаляем общий префикс x. *)
    rewrite Hu in HB.
    repeat rewrite <- app_assoc in HB.
    apply (remove_same_prefix x) in HB.

    destruct s as [|c s].

    + (* s = [] *)
      rewrite app_nil_r in Hu.
      rewrite app_nil_l in Hy.

      apply (remove_same_prefix [A]) in Hy.

      split.

      * symmetry.
        exact Hu.

      * exact Hy.

    + (* s непустой *)
      destruct c.

      * (* Первая буква s равна A,
           но равенство с B требует B. *)
        simpl in HB.
        discriminate HB.

      * (* Первая буква s равна B,
           но равенство с A требует A. *)
        simpl in Hy.
        discriminate Hy.
Qed.


Definition block
  (w1 : word)
  (c : Sigma)
  (w2 : word)
  : word :=
  w1 ++ [c] ++ w2.


Theorem block_decomposition_unique :
  forall w1 w2 w3 w4 : word,
    block w1 A w2 ++ block w1 B w2 =
    block w3 A w4 ++ block w3 B w4 ->
    w1 = w3 /\ w2 = w4.
Proof.
  intros w1 w2 w3 w4 H.

  (* Сохраняем исходное равенство и отдельно рассматриваем длины. *)
  pose proof H as Hlen.

  unfold block in Hlen.

  apply (f_equal (@length Sigma)) in Hlen.

  repeat rewrite app_length in Hlen.
  simpl in Hlen.

  (* Из равенства длин двух пар блоков получаем,
     что первые блоки имеют одинаковую длину. *)
  assert
    (Hblocklen :
       length (block w1 A w2) =
       length (block w3 A w4)).
  {
    unfold block.

    repeat rewrite app_length.
    simpl.

    lia.
  }

  (* Разрезаем равенство всей конструкции
     на равенство A-блоков и равенство B-блоков. *)
  destruct
    (app_split_equal_length
       (block w1 A w2)
       (block w1 B w2)
       (block w3 A w4)
       (block w3 B w4)
       Hblocklen
       H)
    as [HA HB].

  unfold block in HA.
  unfold block in HB.

  (* Используем одновременно разные разделители A и B. *)
  apply (two_markers_unique w1 w2 w3 w4).

  - exact HA.
  - exact HB.
Qed.