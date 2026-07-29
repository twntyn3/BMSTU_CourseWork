Require Import Coq.Lists.List.
Import ListNotations.
Import Nat.
Require Import Coq.Arith.PeanoNat.
Require Import Coq.Arith.Arith Lia.
Require Import ZArith.


Inductive letter := a | c | d | e.

Definition word := list letter.

Fixpoint pow (w : word) (n : nat) : word :=
    match n with
    | 0 => nil
    | S k => w ++ (pow w k)
    end.
Notation "w ^ n" := (pow w n).

(* Функция last от одного аргумента (List.last от двух) *)
Fixpoint last (w : word) : letter :=
    match w with
    | [] => a (* Дефолтное значение при пустом списке *)
    | [l] => l
    | l :: w0 => last w0
    end.

(* Докажем, что введенное определение last совпадает с библиотечным, но имеет более простую нотацию *)
Fact last_eq :
    forall (w : word), last w = List.last w a.
Proof.
    intros. unfold List.last. unfold last. induction w.
    - reflexivity.
    - rewrite IHw. reflexivity.
Qed.

(* Определим базовый циклический (левый) сдвиг как перенос первой буквы в конец слова *)
Definition one_left_cycle_shift (w : word) : word :=
  match w with
  | nil => nil
  | l :: w0 => w0 ++ [l]
  end.
(* Определим базовый циклический (правый) сдвиг как перенос последней буквы в начало слова *)
Definition one_right_cycle_shift (w : word) : word :=
  match w with
  | nil => nil
  | _ :: _ => last w :: (firstn (length w - 1) w)
  end.


(* Свойства сохранения длин после базовых сдвигов *)
Property one_left_cycle_shift_len :
    forall (w : word), length (one_left_cycle_shift w) = length w.
Proof.
    intros w. destruct w.
    - simpl. reflexivity.
    - simpl. rewrite length_app. simpl. rewrite Nat.add_1_r. reflexivity.
Qed.
Property one_right_cycle_shift_len :
    forall (w : word), length (one_right_cycle_shift w) = length w.
Proof.
    intros w. destruct w.
    - simpl. reflexivity.
    - unfold one_right_cycle_shift. simpl. rewrite firstn_length_le.
        (* S (length w - 0) = S (length w) *)
        + rewrite Nat.sub_0_r. reflexivity. 
        (* length w - 0 <= length (l :: w) *)
        + rewrite Nat.sub_0_r. rewrite length_cons. lia. 
Qed.


(* Докажем обратимость операции one_left_cycle_shift *)
Lemma last_app_single : forall (w : word) (l : letter),
  last (w ++ [l]) = l.
Proof.
  intros w l. induction w as [|x xs IH].
  (* last ([] ++ [l]) = l *)
  - simpl. reflexivity.
  (* last ((x :: xs) ++ [l]) = l *)
  - simpl. rewrite IH.
    assert (Hnonempty : xs ++ [l] <> []).
    { intro H. destruct xs; inversion H. }
    destruct (xs ++ [l]) eqn:E.
      (* x = l *)
      + contradiction.
      (* l = l *)
      + reflexivity.
Qed.
Lemma firstn_app_single : forall (w : word) (l : letter),
  firstn (length (w ++ [l]) - 1) (w ++ [l]) = w.
Proof.
  intros w l.
  (* Упрощаем до firstn (length w) (w ++ [l]) = w *)
  rewrite length_app. simpl. rewrite Nat.add_sub.
  (* Раскрываем firstn и упрощаем *)
  rewrite firstn_app. rewrite firstn_all. rewrite Nat.sub_diag.
  simpl. rewrite app_nil_r. reflexivity.
Qed.
Property one_left_cycle_shift_inv :
    forall (w : word), one_right_cycle_shift (one_left_cycle_shift w) = w.
Proof.
    intros w. destruct w.
    (* one_right_cycle_shift (one_left_cycle_shift []) = [] *)
    - simpl. reflexivity.
    (* one_right_cycle_shift (one_left_cycle_shift (l :: w)) = l :: w *)
    - simpl. unfold one_right_cycle_shift.
      rewrite last_app_single. rewrite firstn_app_single. 
      assert (Hnonempty : w ++ [l] <> []).
    { intro H. destruct w; inversion H. }
      destruct (w ++ [l]) eqn:E.
      (* [] = l :: w *)
      + contradiction.
      (* l :: w = l :: w *)
      + reflexivity.
Qed.

(* Следствие из предыдущего свойства - инъективность операции one_left_cycle_shift *)
Corollary one_left_cycle_shift_in :
    forall (w1 w2 : word), one_left_cycle_shift w1 = one_left_cycle_shift w2 -> w1 = w2.
Proof.
    intros w1 w2 H.
    (* Подействуем one_right_cycle_shift с обеих сторон *)
    assert (right_left : one_right_cycle_shift (one_left_cycle_shift w1) =
                           one_right_cycle_shift (one_left_cycle_shift w2)).
    { rewrite H. reflexivity. }
    (* Сокращаем обратные операции *)
    rewrite one_left_cycle_shift_inv in right_left.
    rewrite one_left_cycle_shift_inv in right_left.
    assumption.
Qed.


(* Докажем обратимость операции one_right_cycle_shift *)
Lemma last_cons :
    forall (l : letter) (w : word), length w > 0 -> last (l :: w) = last w.
Proof.
    intros l w H. simpl. destruct w. 
    (* l = last [] *)
    - simpl in H. lia.
    (* last (l0 :: w) = last (l0 :: w) *)
    - reflexivity.
Qed.
Lemma skipn_sub_1 :
    forall (l : letter) (w : word), length w > 0 ->
    skipn (length w) (l :: w) = skipn (length w - 1) w.
Proof.
    intros l w H. destruct w.
    (* skipn (length []) [l] = skipn (length [] - 1) [] *)
    - simpl. simpl in H. lia.
    (* skipn (length (l0 :: w)) (l :: l0 :: w) = skipn (length (l0 :: w) - 1) (l0 :: w) *)
    - simpl. rewrite Nat.sub_0_r. reflexivity. 
Qed.
Lemma last_skipn :
    forall (w : word), length w > 0 -> ([last w] = skipn (length w - 1) w).
Proof.
    intros w H. induction w.
    (* [last []] = skipn (length [] - 1) [] *)
    - simpl in H. lia. (* 0 > 0 *)
    (* [last (a0 :: w)] = skipn (length (a0 :: w) - 1) (a0 :: w) *)
    - destruct w.
        (* [last [a0]] = skipn (length [a0] - 1) [a0] *)
        + simpl. reflexivity.
        (* [last (a0 :: l :: w)] = skipn (length (a0 :: l :: w) - 1) (a0 :: l :: w) *)
        + rewrite last_cons. rewrite length_cons. rewrite Nat.sub_1_r. rewrite Nat.pred_succ.
          rewrite skipn_sub_1. rewrite IHw. reflexivity.
          all : rewrite length_cons; lia. 
Qed.
Property one_right_cycle_shift_inv :
    forall (w : word), one_left_cycle_shift (one_right_cycle_shift w) = w.
Proof.
    intros w. induction w.
    (* one_left_cycle_shift (one_right_cycle_shift []) = [] *)
    - reflexivity.
    (* one_left_cycle_shift (one_right_cycle_shift (a0 :: w)) = a0 :: w *)
    - unfold one_right_cycle_shift.
        (* Непустота слова с хотя бы одной буквой *)
        assert (H_not_nil : w ++ [a0] <> []).
        { intro H. destruct w; inversion H. }
        destruct (w ++ [a0]) as [| x tail] eqn:E.
        + contradiction. (* w ++ [a0] = [] *)
        (* Раскрываем one_left_cycle_shift и last *)
        + unfold one_left_cycle_shift. rewrite last_skipn.
            * rewrite firstn_skipn. reflexivity.
            * destruct (x :: tail).
                ** contradiction. (* H_not_nil : [] <> [] *)
                ** simpl. lia. (* S (length w) > 0 *)
Qed.

(* Следствие из предыдущего свойства - инъективность операции one_right_cycle_shift *)
Corollary one_right_cycle_shift_in :
    forall (w1 w2 : word), one_right_cycle_shift w1 = one_right_cycle_shift w2 -> w1 = w2.
Proof.
    intros w1 w2 H.
    (* Подействуем one_left_cycle_shift с обеих сторон *)
    assert (left_right : one_left_cycle_shift (one_right_cycle_shift w1) =
                           one_left_cycle_shift (one_right_cycle_shift w2)).
    { rewrite H. reflexivity. }
    (* Сокращаем обратные операции *)
    rewrite one_right_cycle_shift_inv in left_right.
    rewrite one_right_cycle_shift_inv in left_right.
    assumption.
Qed.


(* Определим рекурсивно циклические сдвиги на n букв
 как n базовых соответствующих сдвигов *)
Fixpoint left_cycle_shift (w : word) (n : nat) : word :=
  match n with
  | 0 => w
  | S k => left_cycle_shift (one_left_cycle_shift w) k
  end.
Fixpoint right_cycle_shift (w : word) (n : nat) : word :=
  match n with
  | 0 => w
  | S k => right_cycle_shift (one_right_cycle_shift w) k
  end.

(* Докажем свойство сохранения степени при левых сдвигах *)
Lemma left_cycle_shift_nil_pow :
    forall (n : nat), one_left_cycle_shift ([] ^ n) = [] ^ n.
Proof.
    intros n. induction n.
    (* one_left_cycle_shift ([] ^ 0) = [] ^ 0 *)
    - simpl. reflexivity.
    (* one_left_cycle_shift ([] ^ S n) = [] ^ S n *)
    - simpl. rewrite IHn. reflexivity.
Qed.
Lemma inductive_pow_sides :
    forall (l : letter) (w : word) (n : nat), (w ++ (l :: w) ^ n) ++ [l] = (w ++ [l]) ^ S n.
Proof.
    intros l w n. simpl. induction n.
    - simpl. rewrite app_nil_r. rewrite app_nil_r. reflexivity.
    - simpl. rewrite <- app_assoc. rewrite <- app_assoc. rewrite <- IHn. reflexivity.
Qed.
Lemma one_left_cycle_shift_pow_pres :
    forall (w : word) (n : nat), one_left_cycle_shift (w ^ n) = (one_left_cycle_shift w) ^ n.
Proof.
    intros w n. induction n.
    (* one_left_cycle_shift (w ^ 0) = one_left_cycle_shift w ^ 0 *)
    - simpl. reflexivity.
    (* one_left_cycle_shift (w ^ S n) = one_left_cycle_shift w ^ S n *)
    - destruct w.
        (* one_left_cycle_shift ([] ^ S n) = one_left_cycle_shift [] ^ S n *)
        + simpl. apply left_cycle_shift_nil_pow.
        (* one_left_cycle_shift ((l :: w) ^ S n) = one_left_cycle_shift (l :: w) ^ S n *)
        + simpl. simpl in IHn. symmetry in IHn. rewrite inductive_pow_sides. reflexivity.
Qed.
Property left_cycle_shift_pow_pres :
    forall (w : word) (n : nat) (k : nat),
    left_cycle_shift (w ^ n) k = (left_cycle_shift w k) ^ n.
Proof.
    intros w n k. induction k in w |- *. (* Индукция по k с параметризованным w *)
    (* left_cycle_shift (w ^ n) 0 = left_cycle_shift w 0 ^ n *)
    - simpl. reflexivity.
    (* left_cycle_shift (w ^ n) (S k) = left_cycle_shift w (S k) ^ n *)
    - simpl. rewrite one_left_cycle_shift_pow_pres. rewrite IHk. simpl. reflexivity.
Qed.


(* Докажем свойство сохранения степени при правых сдвигах *)
Lemma one_right_cycle_shift_pow_pres :
    forall (w : word) (n : nat), one_right_cycle_shift (w ^ n) = (one_right_cycle_shift w) ^ n.
Proof.
    intros w n.
    (* Докажем, сославшись на аналогичное свойство для левых сдвигов *)
    apply one_left_cycle_shift_in. rewrite one_right_cycle_shift_inv.
    (* w ^ n = one_left_cycle_shift (one_right_cycle_shift w ^ n) *)
    rewrite one_left_cycle_shift_pow_pres. rewrite one_right_cycle_shift_inv. reflexivity.
Qed.
Property right_cycle_shift_pow_pres :
    forall (w : word) (n : nat) (k : nat),
    right_cycle_shift (w ^ n) k = (right_cycle_shift w k) ^ n.
Proof.
    intros w n k. induction k in w |- *. (* Индукция по k с параметризованным w *)
    (* right_cycle_shift (w ^ n) 0 = right_cycle_shift w 0 ^ n *)
    - simpl. reflexivity.
    (* right_cycle_shift (w ^ n) (S k) = right_cycle_shift w (S k) ^ n *)
    - simpl. rewrite one_right_cycle_shift_pow_pres. rewrite IHk. reflexivity.
Qed.


(* Определение простоты слова  *)
Definition is_simple (w : word) : Prop :=
    ~ ( exists (w0 : word) (k : nat), length w0 < length w /\ w0 ^ k = w).

(* Докажем свойство сохранения простоты слова при левых сдвигах *)
Lemma left_cycle_shift_n_1 :
    forall (w : word) (n : nat), left_cycle_shift (one_left_cycle_shift w) n =
                                 one_left_cycle_shift (left_cycle_shift w n).
Proof.
    intros w n. induction n in w |- *. (* Индукция по n с параметризованным w *)
    - simpl. reflexivity.
    - simpl. rewrite IHn. reflexivity.
Qed.
Lemma one_left_cycle_shift_simple_pres :
    forall (w : word), is_simple w -> is_simple (one_left_cycle_shift w).
Proof.
    intros w H. unfold is_simple. intro H_is_pow.
    (* Докажем от противного *)
    destruct H_is_pow as [u [k [Hk Hshift]]]. destruct w.
    (* w = [] *)
    - simpl in *. lia. 
    (* w = l :: w *)
    - simpl in *.
      (* Утверждение для раскрытия w ++ [l] *)
      assert (left_cycle_def : w ++ [l] = one_left_cycle_shift (l :: w)).
    { reflexivity. }
      rewrite left_cycle_def in Hshift.
      (* Утверждение для сокращения one_left_cycle_shift в
      Hshift : u ^ k = one_left_cycle_shift (l :: w) *)
      assert (right_left_u : u = (one_left_cycle_shift (one_right_cycle_shift u))). 
    { rewrite one_right_cycle_shift_inv. reflexivity. }
      rewrite right_left_u in Hshift.
      rewrite <- one_left_cycle_shift_pow_pres in Hshift.
      apply  one_left_cycle_shift_in in Hshift.
      (* Hshift : one_right_cycle_shift u ^ k = l :: w *)
      (* H : is_simple (l :: w) *)
      destruct H. exists (one_right_cycle_shift u). exists k. split.
        (* length (one_right_cycle_shift u) < length (l :: w) *)
        + rewrite one_right_cycle_shift_len. rewrite length_app in Hk. simpl in Hk. 
          rewrite length_cons. rewrite Nat.add_1_r in Hk. assumption.
        (* one_right_cycle_shift u ^ k = l :: w *)
        + rewrite Hshift. reflexivity.
Qed.
Property left_cycle_shift_simple_pres :
    forall (w : word) (n : nat), is_simple w -> is_simple (left_cycle_shift w n).
Proof.
    intros w n H. induction n.
    (* is_simple (left_cycle_shift w 0) *)
    - simpl. assumption.
    (* is_simple (left_cycle_shift w (S n)) *)
    - simpl. rewrite left_cycle_shift_n_1.
      apply one_left_cycle_shift_simple_pres in IHn. assumption.
Qed.

(* Докажем свойство сохранения простоты слова при правых сдвигах *)
Lemma right_cycle_shift_n_1 :
    forall (w : word) (n : nat), right_cycle_shift (one_right_cycle_shift w) n =
                                 one_right_cycle_shift (right_cycle_shift w n).
Proof.
    intros w n. induction n in w |- *. (* Индукция по n с параметризованным w *)
    - simpl. reflexivity.
    - simpl. rewrite IHn. reflexivity.
Qed.
Lemma one_right_cycle_shift_simple_pres :
    forall (w : word), is_simple w -> is_simple (one_right_cycle_shift w).
Proof.
    intros w H. intro.
    (* Докажем от противного *)
    rewrite <- one_right_cycle_shift_inv in H.
    set (w' := (one_right_cycle_shift w)) in *. (* Сделаем замену для более понятного вида *)
    destruct H0 as [w0 [k [Hlen Heq]]]. rewrite <- Heq in H.
    rewrite one_left_cycle_shift_pow_pres in H.
    (* Докажем противоречие в 
    H : is_simple (one_left_cycle_shift w0 ^ k) *)
    unfold is_simple in H. apply H. exists (one_left_cycle_shift w0), k. split.
    (* length (one_left_cycle_shift w0) < length (one_left_cycle_shift w0 ^ k) *)
    - rewrite <- Heq in Hlen. rewrite <- one_left_cycle_shift_pow_pres.
      repeat rewrite one_left_cycle_shift_len. assumption.
    (* one_left_cycle_shift w0 ^ k = one_left_cycle_shift w0 ^ k *)
    - reflexivity.
Qed. 
Property right_cycle_shift_simple_pres :
    forall (w : word) (n : nat), is_simple w -> is_simple (right_cycle_shift w n).
Proof.
    intros w n H. induction n.
    (* is_simple (right_cycle_shift w 0) *)
    - simpl. assumption.
    (* is_simple (right_cycle_shift w (S n)) *)
    - simpl. rewrite right_cycle_shift_n_1.
      apply one_right_cycle_shift_simple_pres in IHn. assumption.
Qed.


(* Обобщенное определение циклического сдвига *)
Definition shift (w : word) (n : Z) : word :=
  let abs_n := Z.to_nat (Z.abs n) in
  if Z.gtb n 0 then
    left_cycle_shift w abs_n
  else if Z.ltb n 0 then
    right_cycle_shift w abs_n
  else
    w.
    
(* Основная теорема о сохранении разложения слова как степень простого числа
   при циклическом сдвиге *)
Theorem shift_simple_pow_pres :
    forall (w : word) (k : nat) (s : Z), is_simple w ->
    ((shift (w ^ k) s) = (shift w s) ^ k /\ is_simple (shift w s)).
Proof.
    intros w k s H.
    unfold shift. split.
    (* Сохранение степени *)
    - destruct s eqn:Hcomp.
        + simpl. reflexivity. (* s = 0 *)
        + simpl. rewrite left_cycle_shift_pow_pres. reflexivity. (* s > 0 => левый сдвиг *)
        + simpl. rewrite right_cycle_shift_pow_pres. reflexivity. (* s < 0 => правый сдвиг *)
    (* Сохранение простоты *)
    - destruct s eqn:Hcomp.
        + simpl. assumption. (* s = 0 *)
        + simpl. apply left_cycle_shift_simple_pres. assumption. (* s > 0 => левый сдвиг *)
        + simpl. apply right_cycle_shift_simple_pres. assumption. (* s < 0 => правый сдвиг *)
Qed.







(* 2 Ступень - (Слабая) Теорема Файна-Вилфа *)
(* Вспомогательные леммы *)
Lemma pow_empty :
    forall (n : nat), [] ^ n = [].
Proof.
    intros n. induction n.
    - simpl. reflexivity.
    - simpl. rewrite IHn. reflexivity.
Qed.
Lemma length_pow :
    forall (w : word) (n :nat), length (w ^ n) = (length w) * n.
Proof.
    intros w n. induction n.
    - simpl. lia.
    - simpl. rewrite length_app. rewrite IHn. lia.
Qed.
Lemma firstn_pow_self :
    forall (w : word) (n : nat), n > 0 -> firstn (length w) (w ^ n) = w.
Proof.
  intros w n Hn. destruct n as [| k].
  - lia.
  - simpl. rewrite firstn_app.
    replace (length w - length w) with 0 by lia.
    simpl. rewrite app_nil_r. rewrite firstn_all. reflexivity.
Qed.
Lemma gcd_div :
    forall (p q : nat), exists p' q' : nat, p = p' * (gcd p q) /\ q = q' * (gcd p q).
Proof.
    intros p q.
    destruct (Nat.gcd_divide_l p q).
    destruct (Nat.gcd_divide_r p q).
    exists x. exists x0. split. all : assumption.
Qed.
Lemma pow_comp :
    forall (w : word) (n p : nat),
    w ^ (n * p) = (w ^ n) ^ p.
Proof.
    intros w n p.
  induction p as [|p' IH].
  - simpl. rewrite Nat.mul_0_r. reflexivity.
  - simpl. rewrite <- IH. rewrite Nat.mul_succ_r. simpl.
    assert (pow_plus : forall (a b : nat), w ^ a ++ w ^ b = w ^ (a + b)).
  { intros a b. induction a as [|a' IH'].
    - simpl. reflexivity.
    - simpl. rewrite <- IH'. rewrite app_assoc. reflexivity. }
    rewrite pow_plus. rewrite Nat.add_comm. reflexivity.
Qed.

(* Докажем свойство инъективности операции возведения в степень слова *)
Property pow_in :
    forall (w1 w2 : word) (n : nat),
    n > 0 ->
    w1 ^ n = w2 ^ n -> w1 = w2.
Proof.
    intros w1 w2 n Hn Heq.
    (* Вспомогательное утверждение про равенство длин слов w1 и w2 *)
    assert (Hlen : length w1 = length w2).
  {
    assert (Hlen_pow : length (w1 ^ n) = length (w2 ^ n)) by (rewrite Heq; reflexivity).
    rewrite !length_pow in Hlen_pow.
    rewrite Nat.mul_cancel_r in Hlen_pow.
    - assumption.
    - lia.
    }
    (* Докажем что первые length w1 = length w2 символов совпадают *)
    assert (Hfirst : firstn (length w1) (w1 ^ n) = firstn (length w1) (w2 ^ n)).
  { rewrite Heq. reflexivity. }
    rewrite Hlen in Hfirst at 2.
    (* По лемме первые length w1 = length w2 символов совпадают с w1 и w2 *)
    rewrite !firstn_pow_self in Hfirst by assumption.
    exact Hfirst.
Qed.

(* Соотношение Безу для положительных натуральных чисел *)
Lemma Bezout :
    forall (p q : nat), p > 0 /\ q > 0 -> exists (u v : nat), u*p-v*q=(gcd p q).
Proof.
    intros p q H.
    destruct H as [Hp Hq].
    (* Докажем с помощью библиотечной леммы *)
    destruct (Nat.gcd_bezout_pos p q).
    - assumption.
    - destruct H as [b Hb]. exists x. rewrite Hb. exists b. 
      rewrite Nat.add_sub. reflexivity.
Qed.

(* Докажем факт об эквивалентности индуктивного определения и определения через
   конкатенацию последних (length w - n) символов и первых n символов (где n < length w)
   левого циклического сдвига, который пригодится для доказательсвта других теорем *)
(* Более общий факт без ограничения на n будет доказан позже *)
Lemma skipn_app_one :
    forall (w : word) (x : letter) (n : nat),
    n <= length w ->
    skipn n (w ++ [x]) = skipn n w ++ [x].
Proof.
  intros w x n.
  (* Докажем по индукции с произвольным w *)
  induction n as [| n' IH] in w |-*.
  - simpl. reflexivity.
  - intros Hlen. destruct w as [| y w0].
    + simpl in Hlen. lia.
    + simpl. apply IH. simpl in Hlen. lia.
Qed.
Lemma firstn_app_one :
    forall (w : word) (x : letter) (n : nat),
    n <= length w ->
    firstn n (w ++ [x]) = firstn n w.
Proof.
  intros w x n.
  (* Докажем по индукции с произвольным w *)
  induction n as [| n' IH] in w |-*.
  - simpl. reflexivity.
  - intros Hlen. destruct w as [| y w0].
    + simpl in Hlen. lia.
    + simpl. f_equal. apply IH. simpl in Hlen. lia.
  Qed.
Fact left_cycle_shift_non_inductive :
    forall (n : nat) (w : word),
    n <= length w ->
    left_cycle_shift w n = skipn n w ++ firstn n w.
Proof.
  intros n. induction n as [| n' IH].
  - intros w _. simpl. rewrite app_nil_r. reflexivity.
  - intros w Hlen.
    simpl.
    destruct w as [| x w0] eqn:E.
    + simpl in Hlen. lia.
    + rewrite IH.
      * simpl.
        assert (Hlen_w0 : n' <= length w0) by (simpl in Hlen; lia).
        rewrite skipn_app_one by exact Hlen_w0.
        rewrite firstn_app_one by exact Hlen_w0.
        rewrite <- app_assoc.
        simpl. reflexivity.
      * rewrite one_left_cycle_shift_len. lia.
Qed.
        

(* Докажем обратимость рекурсивных циклических сдвигов *)
Lemma left_shift_word_length :
    forall (w : word), left_cycle_shift w (length w) = w.
Proof.
    intros w.
    rewrite left_cycle_shift_non_inductive by lia.
    rewrite skipn_all. simpl. rewrite firstn_all. reflexivity.
Qed.
Lemma nil_eq_pow :
    forall (w : word) (n : nat), [] = w ^ n -> w = [] \/ n = 0.
Proof.
    intros w n.  destruct n.
  - right. reflexivity.
  - left.
    destruct w as [|l w0] eqn:E.
    + reflexivity.
    + simpl in H.
      discriminate H.
Qed.
Property left_cycle_shift_inv :
  forall (w : word) (n : nat), right_cycle_shift (left_cycle_shift w n) n = w.
Proof.
    intros w n.
    induction n.
    - simpl. reflexivity.
    - simpl. rewrite left_cycle_shift_n_1.
      assert (step : left_cycle_shift w n =
      one_right_cycle_shift (one_left_cycle_shift (left_cycle_shift w n))).
    { rewrite one_left_cycle_shift_inv. reflexivity. }
      rewrite <- step. assumption.
Qed.
Property right_cycle_shift_inv :
  forall (w : word) (n : nat), left_cycle_shift (right_cycle_shift w n) n = w.
Proof.
    intros w n.
    induction n.
    - simpl. reflexivity.
    - simpl. rewrite right_cycle_shift_n_1. rewrite one_right_cycle_shift_inv.
      assumption.
Qed.

(* Леммы про циклический сдвиг слова на сумму и разность натуральных чисел *)
Lemma w1_nonempty : forall (w1 : word) (k1 : nat) (l : letter) (w : word),
  l :: w = w1 ^ k1 -> length w1 > 0.
Proof.
  intros w1 k1 l w H.
  destruct w1 as [|x xs] eqn:E.
  - simpl in H. destruct k1 as [|k1'].
    + simpl in H. discriminate H.
    + simpl in H.
      rewrite pow_empty in H.
      discriminate.
  - simpl. lia.
Qed.
Lemma left_cycle_shift_add :
    forall (w : word) (n p : nat), left_cycle_shift w (n + p) =
    left_cycle_shift (left_cycle_shift w n) p.
Proof.
    intros w n p. induction n.
    - simpl. reflexivity.
    - simpl. rewrite left_cycle_shift_n_1. rewrite IHn.
      symmetry. rewrite left_cycle_shift_n_1. rewrite left_cycle_shift_n_1.
      reflexivity.
Qed.
Lemma right_cycle_shift_add :
    forall (w : word) (n p : nat), right_cycle_shift w (n + p) =
    right_cycle_shift (right_cycle_shift w n) p.
Proof.
    intros. induction n.
    - simpl. reflexivity.
    - simpl. rewrite right_cycle_shift_n_1. rewrite IHn.
      symmetry. rewrite right_cycle_shift_n_1. rewrite right_cycle_shift_n_1. reflexivity.
Qed.
Lemma left_cycle_shift_sub :
    forall (w : word) (n p : nat), n >= p -> left_cycle_shift w (n - p) =
    right_cycle_shift (left_cycle_shift w n) p.
Proof.
    intros w n p H.
    assert (step : w =
    right_cycle_shift (right_cycle_shift (left_cycle_shift w n) p) (n-p)).
  { rewrite <- right_cycle_shift_add. symmetry. rewrite Nat.add_sub_assoc.
    - rewrite Nat.add_comm. rewrite Nat.add_sub.
      rewrite left_cycle_shift_inv. reflexivity.
    - lia.  }
    assert (step2 : left_cycle_shift (right_cycle_shift (right_cycle_shift (left_cycle_shift w n) p)
(n - p)) (n - p) = right_cycle_shift (left_cycle_shift w n) p).
  { rewrite right_cycle_shift_inv. reflexivity. }
    symmetry. rewrite <- step2. rewrite <- step. reflexivity.
Qed.

(* Важная лемма про равенство суффиксов равной длины у одинаковых слов,
   на которой основан критерий разложения слова в степень *)
Lemma right_shift_word_length :
    forall (w : word), right_cycle_shift w (length w) = w.
Proof.
    intros w.
    assert (left_shift_word_length_apply : left_cycle_shift w (length w) = w).
  { apply left_shift_word_length.  }
    assert (left_shift_inv_apply : right_cycle_shift (left_cycle_shift w (length w)) (length w) =
    right_cycle_shift w (length w)).
  { rewrite left_shift_word_length_apply. reflexivity. }
    rewrite left_cycle_shift_inv in left_shift_inv_apply.
    symmetry. assumption.
Qed.
Lemma suffix_len_eq :
    forall (w1 w2 w3 w4 : word),
    w1 ++ w2 = w3 ++ w4 ->
    length w2 = length w4 ->
    w2 = w4.
Proof.
    intros w1 w2 w3 w4 H Hlen.
    assert (Hlen_pref : length w1 = length w3).
  { assert (lenw1234 : length (w1 ++ w2) = length (w3 ++ w4)). rewrite H. reflexivity.
    rewrite length_app in lenw1234. rewrite length_app in lenw1234.
    rewrite Hlen in lenw1234. apply Nat.add_cancel_r in lenw1234. assumption. }
    assert (step : skipn (length w1) (w1 ++ w2) =
    skipn (length w1) (w3 ++ w4)).
  { rewrite H. reflexivity. }
    rewrite Hlen_pref in step at 2.
    rewrite skipn_app in step. rewrite skipn_app in step.
    rewrite skipn_all in step. rewrite skipn_all in step.
    rewrite Nat.sub_diag in step. rewrite Nat.sub_diag in step.
    simpl in step. exact step.
Qed.

(* Докажем критерий разложения слова в степень другого слова,
   на котором основано доказательство слабой версии теоремы Файна-Вилфа *)
Lemma min_mul : forall (n h d0 : nat),
  min (n * d0) (h * d0) = d0 * min n h.
Proof.
   intros n h d0.
  destruct (Nat.le_ge_cases n h) as [H | H].
  (* n <= h *)
  - rewrite Nat.min_l.
    rewrite Nat.min_l.
    + rewrite Nat.mul_comm. reflexivity.
    + assumption.
    + destruct d0.
      * simpl. lia.
      * apply Nat.mul_le_mono_pos_r.
        ** lia.
        ** assumption.
    (* h <= n *)
  - rewrite Nat.min_r.
    rewrite Nat.min_r.
    + rewrite Nat.mul_comm. reflexivity.
    + assumption.
    + destruct d0.
      * simpl. lia.
      * apply Nat.mul_le_mono_pos_r.
        ** lia.
        ** assumption.
Qed.
Lemma h_d0_sub_d0 :
  forall (h d : nat), h > 0 -> h * d - d = (h - 1) * d.
Proof.
    intros. destruct h.
    - simpl. reflexivity.
    - simpl.  lia.
Qed.
Lemma firstn_add : forall (w : word) (a b : nat),
  a + b <= length w ->
  firstn (a + b) w = firstn a w ++ firstn b (skipn a w).
Proof.
    intros w a b H.
    assert (step : a = length (firstn a w)).
  {rewrite length_firstn. lia. }
    rewrite step at 1.
    assert (step2 : w = (firstn a w) ++ (skipn a w)).
  { rewrite firstn_skipn. reflexivity. }
    rewrite step2 at 2.
    rewrite firstn_app_2. reflexivity.
Qed.
Lemma pow_criteria :
    forall (w : word) (d h : nat), 
    left_cycle_shift w d = w -> 
    length w = h * d /\ h > 0 /\ d > 0-> 
    exists (w' : word), length w' = d /\ w = w' ^ h.
Proof.
    intros. destruct H0 as [Hlen [Hh0 Hd0]]. exists (firstn d0 w). split.
    (* length (firstn d0 w) = d0 *)
    - rewrite firstn_length_le.
        + reflexivity.
        + rewrite Hlen. induction h.
            * lia.
            * simpl. lia.
    - (* w = firstn d0 w ^ h *)
      assert (step : w = firstn (length w) w).
    { rewrite firstn_all. reflexivity. }
      rewrite step at 1. rewrite Hlen.
      (* firstn (h * d0) w = firstn d0 w ^ h *)
      (* Усилим утверждение left_cycle_shift w d0 = w о периодичности   *)
      assert (step2 : forall (n : nat), left_cycle_shift w (n * d0) = w).
    { induction n.
      - simpl. reflexivity.
      - simpl. rewrite Nat.add_comm. rewrite left_cycle_shift_add.
        rewrite IHn. assumption. }
      (* Раскроем циклический сдвиг в left_cycle_shift w (n * d0) = w по неидуктивному определению*)
      assert (step3 : forall (n : nat), n <= h ->
      skipn (n*d0) w ++ firstn (n*d0) w = w).
    { intros. rewrite <- left_cycle_shift_non_inductive.
      - rewrite step2. reflexivity. 
      - rewrite Hlen. apply Nat.mul_le_mono_pos_r. assumption. lia. }
      (* равенство циклических сдвигов: left_cycle_shift w (n * d0) = left_cycle_shift w ((S n) * d0) *)
      assert (step4 : forall (n : nat), n < h ->
      skipn (n * d0) w ++ firstn (n * d0) w =
      skipn ((S n) * d0) w ++ firstn ((S n) * d0) w).
    { intros. rewrite step3. rewrite step3.
      - reflexivity.
      - lia.
      - lia. }
      simpl in step4.
      (* Раскроем firstn (d0 + n * d0) w как конкатенацию (firstn d0 w) и оставшейся части *)
      assert (step5 : forall (n : nat), n < h ->
      skipn (n * d0) w ++ firstn (n * d0) w =
      skipn (d0 + n * d0) w ++ (firstn d0 w) ++ (firstn (n * d0) (skipn d0 w))).
    { intros. rewrite <- firstn_add.
      - rewrite step4.
        + reflexivity.
        + assumption.
      - rewrite Hlen.
        assert (d0_plus_n_d0 : d0 + n * d0 = (S n) * d0).
      { simpl. reflexivity. }
        rewrite d0_plus_n_d0. apply Nat.mul_le_mono_pos_r.
        + assumption.
        + lia. }
      (* С помощью леммы о равенстве суффиксов равной длины уточняем оставшуюся часть из step5 *)
      assert (step6 : forall (n : nat), n < h ->
      firstn (n * d0) (skipn d0 w) = firstn (n * d0) w).
    { intros. symmetry. apply (suffix_len_eq (skipn (n * d0) w) (firstn (n * d0) w)
      (skipn (d0 + n * d0) w ++ firstn d0 w) (firstn (n * d0) (skipn d0 w))).
      - rewrite step5.
        + rewrite app_assoc. reflexivity.
        + assumption.
      - rewrite length_firstn. rewrite length_firstn.
        rewrite length_skipn. rewrite Hlen. rewrite h_d0_sub_d0.
        rewrite min_mul. rewrite min_mul.
        + assert (Hn_le_h : n <= h) by lia.
          assert (Hn_le_h_minus_1 : n <= h - 1) by lia.
          rewrite Nat.min_l. rewrite Nat.min_l; lia. lia.
        + assumption. }
      (* Индуктивный шаг для раскрытия firstn (n * d0) w как степени firstn d0 w *)
      assert (step7 : forall (n : nat), n < h ->
      firstn ((S n)* d0) w = firstn d0 w ++ firstn (n * d0) w).
    { intros. simpl. rewrite firstn_add. rewrite step6.
      - reflexivity.
      - assumption.
      - assert (d0_plus_n_d0 : d0 + n * d0 = (S n) * d0).
      { simpl. reflexivity. }
        rewrite d0_plus_n_d0. rewrite Hlen. apply Nat.mul_le_mono_pos_r.
        + assumption.
        + lia. }
      revert step2 step3 step4 step5 step6 H Hlen Hh0 Hd0.
      (* По индукции по степени доказываем критерий *)
      assert (Hgoal : firstn (h * d0) w = firstn d0 w ^ h).
    { induction h as [|h' IH].
      - simpl. reflexivity.
      - destruct h' as [|h''].
        + simpl. rewrite Nat.add_0_r. rewrite app_nil_r. reflexivity.
        + assert (Hlt : h'' < S h'') by lia.
          rewrite step7 with (n := (S h'')) by lia.
          rewrite IH.
            * reflexivity.
            * intros n H. apply step7. lia.
      }
      rewrite Hgoal. reflexivity.
Qed.

(* Докажем слабую версию теоремы Файна-Вилфа *)
Theorem Fine_Wilf :
    forall (w : word) (p q : nat),
    (exists (w1 : word) (k1 : nat), length w1 = p /\ w = w1 ^ k1) ->
    (exists (w2 : word) (k2 : nat), length w2 = q /\ w = w2 ^ k2) ->
    exists (w3 : word) (k3 : nat), length w3 = (gcd p q) /\ w = w3 ^ k3.
Proof.
    intros w p q H1 H2.
    destruct H1 as [w1 [k1 [lenw1 Hw1]]]. destruct H2 as [w2 [k2 [lenw2 Hw2]]].
    (* Докажем left_cycle_shift w2 p = w2 *)
    assert (step1 : forall (w : word) (n p: nat), left_cycle_shift (w ^ n) p
    = (left_cycle_shift w p) ^ n).
  { symmetry. rewrite left_cycle_shift_pow_pres. reflexivity. }
    assert (step2 : (left_cycle_shift w2 p) ^ k2 = w2 ^ k2).
  { rewrite <- left_cycle_shift_pow_pres. rewrite <- Hw2. rewrite Hw1. rewrite step1.
    rewrite <- lenw1. rewrite left_shift_word_length. reflexivity. }
    (* Докажем left_cycle_shift w2 (x * p) = w2 *)
    destruct k2. (* Разобьем на два случая: k2=0, k2>0 *)
    (* k2=0 *)
    - simpl in *. exists ([a] ^ (gcd p q)). exists 0. rewrite length_pow. simpl.
      rewrite Nat.add_0_r. rewrite Hw2. split. all : reflexivity.
    (* k2=0 *)
    - apply pow_in in step2.
      assert (step2x : forall (x : nat), (left_cycle_shift w2 (x*p)) = w2).
    { induction x.
      - simpl. reflexivity.
      - simpl. rewrite left_cycle_shift_add. rewrite step2. rewrite IHx. reflexivity. }
      (* Докажем left_cycle_shift w2 q = w2 *)
      assert (step3 : right_cycle_shift w2 q = w2).
    { rewrite <- lenw2. rewrite right_shift_word_length. reflexivity. }
      (* Докажем left_cycle_shift w2 (v * q) = w2 *)
      assert (step3v : forall (v : nat), right_cycle_shift w2 (v*q) = w2).
    { induction v.
        - simpl. reflexivity.
        - simpl. rewrite right_cycle_shift_add. rewrite step3. rewrite IHv. reflexivity. }
      destruct w.
      (* Таким образом у w2 есть период p и q *)
      (* Разберем тривиальный случай w = [] *)
      --  apply nil_eq_pow in Hw1. destruct Hw1. apply nil_eq_pow in Hw2. destruct Hw2.
          + rewrite H in lenw1. simpl in lenw1. rewrite H0 in lenw2. simpl in lenw2.
          rewrite <- lenw1. rewrite <- lenw2. exists []. exists 1. simpl. split.
          all : reflexivity.
          + rewrite H in lenw1. simpl in lenw1. rewrite <- lenw1. exists w2. exists 0.
          rewrite lenw2. simpl. split. all : reflexivity.
          + apply nil_eq_pow in Hw2. destruct Hw2.
              ++ rewrite H0 in lenw2. simpl in lenw2. rewrite <- lenw2.
              exists w1. exists 0. rewrite lenw1. rewrite Nat.gcd_0_r. simpl. split.
              all : reflexivity.
              ++ exists ([a] ^ (gcd p q)). exists 0. rewrite length_pow. simpl. split.
              rewrite Nat.add_0_r. all : reflexivity.
      (* length w > 0 *)
      (* Соотношение безу: up - vq = gcd(p, q) *)
      -- destruct (Bezout p q). rewrite <- lenw1. rewrite <- lenw2. split.
          + apply w1_nonempty in Hw1. assumption.
          + apply w1_nonempty in Hw2. assumption.
          (* Докажем left_cycle_shift w2 (gcd p q) = w2 *)
          + destruct (gcd_div p q) as [p' [q' [Hp' Hq']]].
          (* Два случая: q'=0, q'>0 *)
            destruct q'.
            * simpl in Hq'. rewrite Hq' in lenw2. apply length_zero_iff_nil in lenw2.
              rewrite lenw2 in Hw2. simpl in Hw2. rewrite pow_empty in Hw2. discriminate.
            * set (q'' := (S q')) in *.
              (* Применим критерий разложения в степень - достаточно доказать,
                 что у w2 также есть период (gcd p q) и что длина w2 делится на (gcd p q) *)
              destruct (pow_criteria w2 (gcd p q) q'') as [w' [Hpow1 Hpow2]].
              (* Вспомогательные утверждения *)
              assert (Hw1_nonempty : length w1 > 0).
            { apply w1_nonempty in Hw1. assumption. }
              assert (Hp_gt_0 : p > 0).
            { rewrite <- lenw1. exact Hw1_nonempty. }
              assert (gcd_gt_0 : (gcd p q) > 0).
            { destruct gcd. lia. lia. }      
              assert (step4 : left_cycle_shift w2 (gcd p q) = w2).
            { destruct H as [v Hv]. rewrite <- Hv. rewrite left_cycle_shift_sub.
            - rewrite step2x. rewrite step3v. reflexivity.
            - symmetry in Hv. rewrite Hv in gcd_gt_0. lia. }
              (* Докажем периодичность *)
              ** exact step4.
              (* Докажем делимость на (gcd p q) *)
              ** rewrite lenw2. split.
                *** assumption.
                *** split.
                  **** lia.
                  **** assert (Hw1_nonempty : length w1 > 0).
                      { apply w1_nonempty in Hw1. assumption. }
                        assert (Hp_gt_0 : p > 0).
                      { rewrite <- lenw1. exact Hw1_nonempty. }
                        destruct gcd. lia. lia.
              (* Наконец докажем теорему Файна-Вилфа, показав, что w разлогается в степень (по критерию) *)
              ** set (Word := (l :: w)) in *. exists w'. rewrite Hw2. exists (q'' * (S k2)). split.
                *** exact Hpow1.
                *** rewrite pow_comp. rewrite Hpow2. reflexivity.
      (* S k2 > 0 - требование инъективности степени *)
      -- lia. 
Qed.

(* Докажем эквивалентность индуктивного и неидуктивного определений левого циклического сдвига *)
Lemma left_cycle_shift_length_mul : forall (w : word) (t : nat),
  left_cycle_shift w (t * length w) = w.
Proof.
  intros w t.
  induction t as [|t' IH].
  - simpl. reflexivity.
  - rewrite Nat.mul_succ_l. rewrite Nat.add_comm.
    rewrite left_cycle_shift_add. 
    rewrite left_shift_word_length.
    rewrite IH.
    reflexivity.
Qed.
Fact left_cycle_shift_eq_def :
    forall (n : nat) (w : word),
    left_cycle_shift w n = skipn (n mod (length w)) w ++ firstn (n mod (length w)) w.
Proof.
    intros.
    destruct (Nat.lt_ge_cases n (length w)).
    (* n < length w *)
    - rewrite left_cycle_shift_non_inductive. rewrite Nat.mod_small. reflexivity. all : lia.
    (* n >= length w *)
    - destruct w. (* Два случая: w = [], w != [] *)
      + (* w' = [] *)
        simpl. induction n as [|n' IH].
        * simpl. reflexivity.
        * simpl. rewrite IH.
          ** rewrite skipn_nil. rewrite firstn_nil. simpl. reflexivity.
          ** simpl. lia.
      + (* w' = l :: w *)
        assert (lenw' : length (l :: w) > 0) by ( simpl; lia). set (w' := l :: w) in *.
        assert (mod_big : forall (n k : nat), n >= k /\ k > 0 -> (exists (t1 t2 : nat), n = k*t1+t2 /\ t2 <k)).
      { intros. destruct H0 as [Hn0 Hk0]. exists (n0 / k). exists (n0 mod k). split.
        - apply Nat.div_mod. lia.
        - apply Nat.mod_upper_bound. lia.
      }
        destruct (mod_big n (length w')) as [t1 [t2 [Hn Ht]]].
        * split. all : assumption.
        * rewrite Hn. rewrite Nat.add_comm. rewrite Nat.mul_comm. rewrite Nat.Div0.mod_add.
          rewrite Nat.mod_small. rewrite Nat.add_comm. rewrite left_cycle_shift_add.
          rewrite left_cycle_shift_length_mul. rewrite left_cycle_shift_non_inductive. reflexivity.
          all : lia.
Qed.
          