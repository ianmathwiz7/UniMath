Require Import UniMath.Foundations.Basics.PartD.
Require Import UniMath.Foundations.Basics.Propositions.
Require Import UniMath.Foundations.Basics.Sets.

Require Import UniMath.CategoryTheory.total2_paths.
Require Import UniMath.CategoryTheory.precategories.
Require Import UniMath.CategoryTheory.functor_categories.
Require Import UniMath.CategoryTheory.UnicodeNotations.
Require Import UniMath.CategoryTheory.limits.graphs.colimits.
Require Import UniMath.CategoryTheory.category_hset.
Require Import UniMath.CategoryTheory.category_hset_structures.
Require Import UniMath.CategoryTheory.limits.initial.
Require Import UniMath.CategoryTheory.FunctorAlgebras.
Require Import UniMath.CategoryTheory.limits.FunctorsPointwiseProduct.
Require Import UniMath.CategoryTheory.limits.FunctorsPointwiseCoproduct.
Require Import UniMath.CategoryTheory.limits.products.
Require Import UniMath.CategoryTheory.limits.terminal.
Require Import UniMath.CategoryTheory.chains.
Require Import UniMath.CategoryTheory.cocontfunctors.
Require Import UniMath.CategoryTheory.exponentials.
Require Import UniMath.CategoryTheory.limits.coproducts.

Local Notation "# F" := (functor_on_morphisms F) (at level 3).
Local Notation "[ C , D , hs ]" := (functor_precategory C D hs).

(* Lists as the colimit of a chain given by the list functor: F(X) = 1 + A * X *)
Section lists.

Variable A : HSET.

Local Open Scope cocont_functor_hset_scope.

(* F(X) = 1 + (A * X) *)
Definition listOmegaFunctor : omega_cocont_functor HSET HSET := '1 + 'A * Id.

Let listFunctor : functor HSET HSET := pr1 listOmegaFunctor.
Let is_omega_cocont_listFunctor : is_omega_cocont listFunctor := pr2 listOmegaFunctor.

Lemma listFunctor_Initial :
  Initial (precategory_FunctorAlg listFunctor has_homsets_HSET).
Proof.
apply (colimAlgInitial _ _ _ is_omega_cocont_listFunctor InitialHSET (ColimCoconeHSET _ _)).
Defined.

Definition List : HSET :=
  alg_carrier _ (InitialObject listFunctor_Initial).

Let List_mor : HSET⟦listFunctor List,List⟧ :=
  alg_map _ (InitialObject listFunctor_Initial).

Let List_alg : algebra_ob listFunctor :=
  InitialObject listFunctor_Initial.

Definition nil_map : HSET⟦unitHSET,List⟧ :=
  CoproductIn1 HSET _ ;; List_mor.

Definition nil : pr1 List := nil_map tt.

Definition cons_map : HSET⟦(A × List)%set,List⟧ :=
  CoproductIn2 HSET _ ;; List_mor.

Definition cons : pr1 A × pr1 List -> pr1 List := cons_map.

(* Get recursion/iteration scheme: *)

(*    x : X           f : A × X -> X *)
(* ------------------------------------ *)
(*       foldr x f : List A -> X *)

Definition mk_listAlgebra (X : HSET) (x : pr1 X)
  (f : HSET⟦(A × X)%set,X⟧) : algebra_ob listFunctor.
Proof.
set (x' := λ (_ : unit), x).
apply (tpair _ X (sumofmaps x' f) : algebra_ob listFunctor).
Defined.

Definition foldr_map (X : HSET) (x : pr1 X) (f : HSET⟦(A × X)%set,X⟧) :
  algebra_mor _ List_alg (mk_listAlgebra X x f).
Proof.
apply (InitialArrow listFunctor_Initial (mk_listAlgebra X x f)).
Defined.

Definition foldr (X : HSET) (x : pr1 X)
  (f : pr1 A × pr1 X -> pr1 X) : pr1 List -> pr1 X.
Proof.
apply (foldr_map _ x f).
Defined.

(* Maybe quantify over "λ _ : unit, x" instead of nil? *)
Lemma foldr_nil (X : hSet) (x : X) (f : pr1 A × X -> X) : foldr X x f nil = x.
Proof.
assert (F := maponpaths (fun x => CoproductIn1 _ _ ;; x)
                        (algebra_mor_commutes _ _ _ (foldr_map X x f))).
apply (toforallpaths _ _ _ F tt).
Qed.

Lemma foldr_cons (X : hSet) (x : X) (f : pr1 A × X -> X)
                 (a : pr1 A) (l : pr1 List) :
  foldr X x f (cons (a,,l)) = f (a,,foldr X x f l).
Proof.
assert (F := maponpaths (fun x => CoproductIn2 _ _ ;; x)
                        (algebra_mor_commutes _ _ _ (foldr_map X x f))).
assert (Fal := toforallpaths _ _ _ F (a,,l)).
clear F.
unfold compose in Fal.
simpl in Fal.
apply Fal.
Opaque foldr_map.
Qed. (* This Qed is slow unless foldr_map is Opaque *)
Transparent foldr_map.

(* This defines the induction principle for lists using foldr *)
Section list_induction.

Variables (P : pr1 List -> UU) (PhSet : forall l, isaset (P l)).
Variables (P0 : P nil)
          (Pc : forall (a : pr1 A) (l : pr1 List), P l -> P (cons (a,,l))).

Let P' : UU := Σ l, P l.
Let P0' : P' := (nil,, P0).
Let Pc' : pr1 A × P' -> P' :=
  λ ap : pr1 A × P', cons (pr1 ap,, pr1 (pr2 ap)),,Pc (pr1 ap) (pr1 (pr2 ap)) (pr2 (pr2 ap)).

Definition P'HSET : HSET.
Proof.
apply (tpair _ P').
abstract (apply (isofhleveltotal2 2); [ apply setproperty | intro x; apply PhSet ]).
Defined.

(* This line is crucial for isalghom_pr1foldr to typecheck *)
Opaque is_omega_cocont_listFunctor.

Lemma isalghom_pr1foldr :
  is_algebra_mor _ List_alg List_alg (fun l => pr1 (foldr P'HSET P0' Pc' l)).
Proof.
apply CoproductArrow_eq_cor.
- apply funextfun; intro x; destruct x; apply idpath.
- apply funextfun; intro x; destruct x as [a l].
  apply (maponpaths pr1 (foldr_cons P'HSET P0' Pc' a l)).
Qed.

Transparent is_omega_cocont_listFunctor.

Definition pr1foldr_algmor : algebra_mor _ List_alg List_alg :=
  tpair _ _ isalghom_pr1foldr.

Lemma pr1foldr_algmor_identity : identity _ = pr1foldr_algmor.
Proof.
now rewrite <- (InitialEndo_is_identity _ listFunctor_Initial pr1foldr_algmor).
Qed.

Lemma listInd l : P l.
Proof.
assert (H : pr1 (foldr P'HSET P0' Pc' l) = l).
  apply (toforallpaths _ _ _ (!pr1foldr_algmor_identity) l).
rewrite <- H.
apply (pr2 (foldr P'HSET P0' Pc' l)).
Defined.

End list_induction.

Lemma listIndProp (P : pr1 List -> UU) (HP : forall l, isaprop (P l)) :
  P nil -> (forall a l, P l → P (cons (a,, l))) -> forall l, P l.
Proof.
intros Pnil Pcons.
apply listInd; try assumption.
intro l; apply isasetaprop, HP.
Defined.

Require Import UniMath.Foundations.NumberSystems.NaturalNumbers.

Local Open Scope nat_scope.

Definition natHSET : HSET.
Proof.
exists nat.
abstract (apply isasetnat).
Defined.

Definition length : pr1 List -> nat :=
  foldr natHSET 0 (fun x => S (pr2 x)).

Definition map (f : pr1 A -> pr1 A) : pr1 List -> pr1 List :=
  foldr _ nil (λ xxs : pr1 A × pr1 List, cons (f (pr1 xxs),, pr2 xxs)).

Lemma length_map (f : pr1 A -> pr1 A) : forall xs, length (map f xs) = length xs.
Proof.
apply listIndProp.
- intros l; apply isasetnat.
- apply idpath.
- simpl; unfold map, length; simpl; intros a l Hl.
  simpl.
  now rewrite !foldr_cons, <- Hl.
Qed.

End lists.

(* Some examples of computations with lists over nat *)
Section nat_examples.

Definition cons_nat a l : pr1 (List natHSET) := cons natHSET (a,,l).

Infix "::" := cons_nat.
Notation "[]" := (nil natHSET) (at level 0, format "[]").

Definition testlist : pr1 (List natHSET) := 5 :: 2 :: [].

Definition testlistS : pr1 (List natHSET) :=
  map natHSET S testlist.

Definition sum : pr1 (List natHSET) -> nat :=
  foldr natHSET natHSET 0 (fun xy => pr1 xy + pr2 xy).

(* None of these compute *)
(* Eval cbn in length _ (nil natHSET). *)
(* Eval vm_compute in length _ testlist. *)
(* Eval vm_compute in length _ testlistS. *)
(* Eval vm_compute in sum testlist. *)
(* Eval vm_compute in sum testlistS. *)

Goal (forall l, length _ (2 :: l) = S (length _ l)).
simpl.
intro l.
try apply idpath. (* this doesn't work *)
unfold length, cons_nat.
rewrite foldr_cons. cbn.
apply idpath.
Abort.

(* some experiments: *)

(* Definition const {A B : UU} : A -> B -> A := fun x _ => x. *)

(* Eval compute in const 0 (nil natHSET). *)

(* Axiom const' : forall {A B : UU}, A -> B -> A. *)

(* Eval compute in const' 0 1. *)
(* Eval compute in const' 0 (nil natHSET). *)

(* Time Eval vm_compute in nil natHSET.  (* This crashes my computer by using up all memory *) *)

End nat_examples.

(* Alternative and more general definition of lists (inspired by a
   remark of Voevodsky) *)
Section list.

(* Remark: I think if you really need lists you should prove a theorem
that establishes a weq between the lists that you have defined and
lists defined as total2 ( fun n : nat => iterprod n A ) where iterprod
n A is defined by induction such that iterprod 0 A = unit, iterprod 1
A = A and iterprod ( S n ) A = dirprod (iterprod n A) A for n=S n’. *)

Fixpoint iterprod (n : nat) (A : UU) : UU := match n with
  | O => unit
  | S n' => dirprod A (iterprod n' A)
  end.

Definition list (A : UU) := total2 (fun n => iterprod n A).

Definition nil_list (A : UU) : list A := (0,,tt).
Definition cons_list (A : UU) (x : A) (xs : list A) : list A :=
  (S (pr1 xs),, (x,, pr2 xs)).

Lemma list_ind : ∀ (A : Type) (P : list A -> UU),
    P (nil_list A)
  -> (∀ (x : A) (xs : list A), P xs -> P (cons_list A x xs))
  -> ∀ xs, P xs.
Proof.
intros A P Hnil Hcons xs.
destruct xs as [n xs].
induction n.
- destruct xs.
  apply Hnil.
- destruct xs as [x xs].
  apply (Hcons x (n,,xs) (IHn xs)).
Defined.

Definition foldr_list {A B : UU} (f : A -> B -> B) (b : B) : list A -> B :=
  list_ind A (fun _ => B) b (fun a _ b' => f a b').

(* Variation of foldr that returns a for the empty list and folds the
   rest with the first element as new default value *)
Definition foldr1_list {A : UU} (f : A -> A -> A) (a : A) (l : list A) : A.
Proof.
destruct l as [n xs].
destruct n.
- apply a.
- induction n as [|n F].
  + apply (pr1 xs).
  + apply (f (pr1 xs) (F (pr2 xs))).
Defined.

Definition map_list {A B : UU} (f : A -> B) : list A -> list B.
Proof.
apply foldr_list.
+ intros a l.
  apply (cons_list B (f a) l).
+ apply (nil_list B).
Defined.

(* Eval compute in (foldr_list (fun (x y : nat) => x + y) 0 (cons_list nat 3 (cons_list nat 2 (nil_list nat)))). *)

Lemma isaset_list (A : HSET) : isaset (list (pr1 A)).
Proof.
apply isaset_total2; [apply isasetnat|].
intro n; induction n; simpl; [apply isasetunit|].
apply isaset_dirprod; [ apply setproperty | apply IHn ].
Qed.

Definition to_List (A : HSET) : list (pr1 A) -> pr1 (List A).
Proof.
intros l.
destruct l as [n l].
induction n.
+ exact (nil A).
+ apply (cons _ (pr1 l,,IHn (pr2 l))).
Defined.

Definition to_list (A : HSET) : pr1 (List A) -> list (pr1 A).
Proof.
apply (foldr A (list (pr1 A),,isaset_list A)).
* apply (0,,tt).
* intros L.
  apply (tpair _ (S (pr1 (pr2 L))) (pr1 L,,pr2 (pr2 L))).
Defined.

Lemma to_listK (A : HSET) : ∀ x : list (pr1 A), to_list A (to_List A x) = x.
Proof.
intro l; destruct l as [n l]; unfold to_list, to_List.
induction n; simpl.
- rewrite foldr_nil.
  destruct l.
  apply idpath.
- rewrite foldr_cons; simpl.
  rewrite IHn; simpl; rewrite <- (paireta l).
  apply idpath.
Qed.

Lemma to_ListK (A : HSET) : ∀ y : pr1 (List A), to_List A (to_list A y) = y.
Proof.
apply listIndProp.
* intro l; apply setproperty.
* unfold to_list; rewrite foldr_nil.
  apply idpath.
* unfold to_list, to_List; intros a l IH.
  rewrite foldr_cons; simpl.
  apply maponpaths, maponpaths, pathsinv0.
  eapply pathscomp0; [eapply pathsinv0, IH|]; simpl.
  now destruct foldr.
Qed.

Lemma weq_list (A : HSET) : list (pr1 A) ≃ pr1 (List A).
Proof.
mkpair.
- apply to_List.
- simple refine (gradth _ _ _ _).
  + apply to_list.
  + apply to_listK.
  + apply to_ListK.
Defined.

(* This doesn't compute: *)
(* Eval compute in (to_list _ testlist).b
 *)

End list.



(** Alternative version of lists using a more direct proof of
    omega-cocontinuity *)
Module AltList.

(* The functor "x * F" is omega_cocont. This is only proved for set at the
   moment as it needs that the category is cartesian closed *)
Section constprod_functor.

Variables (x : HSET).

Definition constprod_functor : functor HSET HSET :=
  product_functor HSET HSET ProductsHSET (constant_functor HSET HSET x)
                                         (functor_identity HSET).

Definition flip {A B C : UU} (f : A -> B -> C) : B -> A -> C := fun x y => f y x.

Lemma omega_cocontConstProdFunctor : is_omega_cocont constprod_functor.
Proof.
intros hF c L ccL HcL cc.
simple refine (tpair _ _ _).
- simple refine (tpair _ _ _).
  + simpl; apply uncurry, flip.
    apply (colimArrow (mk_ColimCocone _ _ _ ccL) (hset_fun_space x HcL)).
    simple refine (mk_cocone _ _).
    * simpl; intro n; apply flip, curry, (pr1 cc).
    * abstract (destruct cc as [f hf]; simpl; intros m n e;
                rewrite <- (hf m n e); destruct e; simpl;
                repeat (apply funextfun; intro); apply idpath).
  + cbn.
    abstract (
    destruct cc as [f hf]; simpl; intro n;
    apply funextfun; intro p; rewrite (paireta p);
    generalize (colimArrowCommutes (mk_ColimCocone hF c L ccL) _
                 (mk_cocone _ (omega_cocontConstProdFunctor_subproof
                               hF c L ccL HcL (f,,hf))) n);
    unfold flip, curry, colimIn; simpl; intro H;
    now rewrite <- (toforallpaths _ _ _ (toforallpaths _ _ _ H (pr2 p)) (pr1 p))).
- abstract (
  intro p; unfold uncurry; simpl; apply subtypeEquality; simpl;
  [ intro g; apply impred; intro t;
    simple refine (let ff : HSET ⟦(x × dob hF t)%set,HcL⟧ := _ in _);
    [ simpl; apply (pr1 cc)
    | apply (@has_homsets_HSET _ HcL _ ff) ]
  | destruct p as [t p]; simpl;
    apply funextfun; intro xc; destruct xc as [x' c']; simpl;
    simple refine (let g : HSET⟦colim (mk_ColimCocone hF c L ccL),
                                hset_fun_space x HcL⟧ := _ in _);
    [ simpl; apply flip, curry, t
    | rewrite <- (colimArrowUnique _ _ _ g); [apply idpath | ];
      destruct cc as [f hf]; simpl in *;
      now intro n; simpl; rewrite <- (p n) ]
  ]).
Defined.

End constprod_functor.

(* The functor "x + F" is omega_cocont.
   Assumes that the category has coproducts *)
Section constcoprod_functor.

Variables (C : precategory) (hsC : has_homsets C) (x : C) (PC : Coproducts C).

Definition constcoprod_functor : functor C C :=
  coproduct_functor C C PC (constant_functor C C x) (functor_identity C).

Lemma omega_cocontConstCoprodFunctor : is_omega_cocont constcoprod_functor.
Proof.
intros hF c L ccL HcL cc.
simple refine (tpair _ _ _).
- simple refine (tpair _ _ _).
  + eapply CoproductArrow.
    * exact (CoproductIn1 _ (PC x (dob hF 0)) ;; pr1 cc 0).
    * simple refine (let ccHcL : cocone hF HcL := _ in _).
      { simple refine (mk_cocone _ _).
        - intros n; exact (CoproductIn2 _ (PC x (dob hF n)) ;; pr1 cc n).
        - abstract (
            intros m n e; destruct e; simpl;
            destruct cc as [f hf]; simpl in *; unfold coproduct_functor_ob in *;
            rewrite <- (hf m _ (idpath _)), !assoc; apply cancel_postcomposition;
            now unfold coproduct_functor_mor; rewrite CoproductOfArrowsIn2). }
      apply (pr1 (pr1 (ccL HcL ccHcL))).
  + abstract (
    destruct cc as [f hf]; simpl in *; unfold coproduct_functor_ob in *;
    simpl; intro n; unfold coproduct_functor_mor in *;
    rewrite precompWithCoproductArrow; apply pathsinv0, CoproductArrowUnique;
    [ rewrite id_left; induction n; [apply idpath|];
      now rewrite <- IHn, <- (hf n _ (idpath _)), assoc,
                  CoproductOfArrowsIn1, id_left
    | rewrite <- (hf n _ (idpath _)); destruct ccL; destruct t; simpl in *;
      rewrite p0; apply maponpaths, hf]).
- abstract (
  destruct cc as [f hf]; simpl in *; unfold coproduct_functor_ob in *;
  intro t; apply subtypeEquality; simpl;
  [ intro g; apply impred; intro; apply hsC
  | destruct t; destruct ccL; unfold coproduct_functor_mor in *; destruct t0; simpl;
    apply CoproductArrowUnique;
    [ now rewrite <- (p 0), assoc, CoproductOfArrowsIn1, id_left
    | simple refine (let temp : Σ x0 : C ⟦ c, HcL ⟧, ∀ v : nat,
         coconeIn L v ;; x0 = CoproductIn2 C (PC x (dob hF v)) ;; f v := _ in _);
         [ apply (tpair _ (CoproductIn2 C (PC x c) ;; t));
          now intro n; rewrite <- (p n), !assoc, CoproductOfArrowsIn2|];
      apply (maponpaths pr1 (p0 temp))]]).
Defined.

End constcoprod_functor.

(* Lists as the colimit of a chain given by the list functor: F(X) = 1 + A * X *)
Section lists.

Variable A : HSET.

(* F(X) = A * X *)
Definition stream : functor HSET HSET := constprod_functor1 ProductsHSET A.

(* F(X) = 1 + (A * X) *)
Definition listFunctor : functor HSET HSET :=
  functor_composite stream (constcoprod_functor _ unitHSET CoproductsHSET).

Lemma omega_cocont_listFunctor : is_omega_cocont listFunctor.
Proof.
apply (is_omega_cocont_functor_composite has_homsets_HSET).
- apply omega_cocontConstProdFunctor.
(* If I use this length doesn't compute with vm_compute... *)
(* - apply (omega_cocont_constprod_functor1 _ _ has_homsets_HSET has_exponentials_HSET). *)
- apply (omega_cocontConstCoprodFunctor _ has_homsets_HSET).
Defined.

Lemma listFunctor_Initial :
  Initial (precategory_FunctorAlg listFunctor has_homsets_HSET).
Proof.
apply (colimAlgInitial _ _ _ omega_cocont_listFunctor
                       InitialHSET (ColimCoconeHSET _ _)).
Defined.

Definition List : HSET :=
  alg_carrier _ (InitialObject listFunctor_Initial).

Let List_mor : HSET⟦listFunctor List,List⟧ :=
  alg_map _ (InitialObject listFunctor_Initial).

Let List_alg : algebra_ob listFunctor :=
  InitialObject listFunctor_Initial.

Definition nil_map : HSET⟦unitHSET,List⟧.
Proof.
simpl; intro x.
apply List_mor, inl, x.
Defined.

Definition nil : pr1 List := nil_map tt.

Definition cons_map : HSET⟦(A × List)%set,List⟧.
Proof.
intros xs.
apply List_mor, (inr xs).
Defined.

Definition cons : pr1 A × pr1 List -> pr1 List := cons_map.

(* Get recursion/iteration scheme: *)

(*    x : X           f : A × X -> X *)
(* ------------------------------------ *)
(*       foldr x f : List A -> X *)

Definition mk_listAlgebra (X : HSET) (x : pr1 X)
  (f : HSET⟦(A × X)%set,X⟧) : algebra_ob listFunctor.
Proof.
set (x' := λ (_ : unit), x).
apply (tpair _ X (sumofmaps x' f) : algebra_ob listFunctor).
Defined.

Definition foldr_map (X : HSET) (x : pr1 X) (f : HSET⟦(A × X)%set,X⟧) :
  algebra_mor _ List_alg (mk_listAlgebra X x f).
Proof.
apply (InitialArrow listFunctor_Initial (mk_listAlgebra X x f)).
Defined.

Definition foldr (X : HSET) (x : pr1 X)
  (f : pr1 A × pr1 X -> pr1 X) : pr1 List -> pr1 X.
Proof.
apply (foldr_map _ x f).
Defined.

(* Maybe quantify over "λ _ : unit, x" instead of nil? *)
Lemma foldr_nil (X : hSet) (x : X) (f : pr1 A × X -> X) : foldr X x f nil = x.
Proof.
assert (F := maponpaths (fun x => CoproductIn1 _ _ ;; x)
                        (algebra_mor_commutes _ _ _ (foldr_map X x f))).
apply (toforallpaths _ _ _ F tt).
Qed.

Lemma foldr_cons (X : hSet) (x : X) (f : pr1 A × X -> X)
                 (a : pr1 A) (l : pr1 List) :
  foldr X x f (cons (a,,l)) = f (a,,foldr X x f l).
Proof.
assert (F := maponpaths (fun x => CoproductIn2 _ _ ;; x)
                        (algebra_mor_commutes _ _ _ (foldr_map X x f))).
assert (Fal := toforallpaths _ _ _ F (a,,l)).
clear F.
(* apply Fal. *) (* This doesn't work here. why? *)
unfold compose in Fal.
simpl in Fal.
apply Fal.
Opaque foldr_map.
Qed. (* This Qed is slow unless one has the Opaque command above *)
Transparent foldr_map.

(* This defines the induction principle for lists using foldr *)
Section list_induction.

Variables (P : pr1 List -> UU) (PhSet : forall l, isaset (P l)).
Variables (P0 : P nil)
          (Pc : forall (a : pr1 A) (l : pr1 List), P l -> P (cons (a,,l))).

Let P' : UU := Σ l, P l.
Let P0' : P' := (nil,, P0).
Let Pc' : pr1 A × P' -> P' :=
  λ ap : pr1 A × P', cons (pr1 ap,, pr1 (pr2 ap)),,Pc (pr1 ap) (pr1 (pr2 ap)) (pr2 (pr2 ap)).

Definition P'HSET : HSET.
Proof.
apply (tpair _ P').
abstract (apply (isofhleveltotal2 2); [ apply setproperty | intro x; apply PhSet ]).
Defined.

Lemma isalghom_pr1foldr :
  is_algebra_mor _ List_alg List_alg (fun l => pr1 (foldr P'HSET P0' Pc' l)).
Proof.
apply CoproductArrow_eq_cor.
- apply funextfun; intro x; destruct x; apply idpath.
- apply funextfun; intro x; destruct x as [a l].
  apply (maponpaths pr1 (foldr_cons P'HSET P0' Pc' a l)).
Qed.

Definition pr1foldr_algmor : algebra_mor _ List_alg List_alg :=
  tpair _ _ isalghom_pr1foldr.

Lemma pr1foldr_algmor_identity : identity _ = pr1foldr_algmor.
Proof.
now rewrite <- (InitialEndo_is_identity _ listFunctor_Initial pr1foldr_algmor).
Qed.

Lemma listInd l : P l.
Proof.
assert (H : pr1 (foldr P'HSET P0' Pc' l) = l).
  apply (toforallpaths _ _ _ (!pr1foldr_algmor_identity) l).
rewrite <- H.
apply (pr2 (foldr P'HSET P0' Pc' l)).
Defined.

End list_induction.

Lemma listIndProp (P : pr1 List -> UU) (HP : forall l, isaprop (P l)) :
  P nil -> (forall a l, P l → P (cons (a,, l))) -> forall l, P l.
Proof.
intros Pnil Pcons.
apply listInd; try assumption.
intro l; apply isasetaprop, HP.
Defined.

Definition natHSET : HSET.
Proof.
exists nat.
abstract (apply isasetnat).
Defined.

Definition length : pr1 List -> nat :=
  foldr natHSET 0 (fun x => S (pr2 x)).

Definition map (f : pr1 A -> pr1 A) : pr1 List -> pr1 List :=
  foldr _ nil (λ xxs : pr1 A × pr1 List, cons (f (pr1 xxs),, pr2 xxs)).

Lemma length_map (f : pr1 A -> pr1 A) : forall xs, length (map f xs) = length xs.
Proof.
apply listIndProp.
- intros l; apply isasetnat.
- apply idpath.
- simpl; unfold map, length; simpl; intros a l Hl.
  simpl.
  now rewrite !foldr_cons, <- Hl.
Qed.

End lists.

(* Some examples of computations with lists over nat *)
Section nat_examples.

Definition cons_nat a l : pr1 (List natHSET) := cons natHSET (a,,l).

Infix "::" := cons_nat.
Notation "[]" := (nil natHSET) (at level 0, format "[]").

Definition testlist : pr1 (List natHSET) := 5 :: 2 :: [].

Definition testlistS : pr1 (List natHSET) :=
  map natHSET S testlist.

Definition sum : pr1 (List natHSET) -> nat :=
  foldr natHSET natHSET 0 (fun xy => pr1 xy + pr2 xy).

(* All of these work *)
(* Eval cbn in length _ (nil natHSET). *)
(* Eval vm_compute in length _ testlist. *)
(* Eval vm_compute in length _ testlistS. *)
(* Eval vm_compute in sum testlist. *)
(* Eval vm_compute in sum testlistS. *)

(* Goal length _ testlist = 2. *)
(* vm_compute. *)
(* Restart. *)
(* cbn. *)
(* Restart. *)
(* compute.  (* does not work when foldr is opaque with "Opaque foldr." *) *)
(* Restart. *)
(* cbv.   (* does not work when foldr is opaque with "Opaque foldr." *) *)
(* Restart. *)
(* native_compute. *)
(* Abort. *)

Goal (forall l, length _ (2 :: l) = S (length _ l)).
simpl.
intro l.
try apply idpath. (* this doesn't work *)
unfold length, cons_nat.
rewrite foldr_cons. cbn.
apply idpath.
Abort.

End nat_examples.
End AltList.