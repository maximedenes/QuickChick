Require Import QuickChick.

Require Import List.
Require Import ZArith.

Require Import Machine.
Require Import Generation.

Require Import String.

Local Open Scope string.

Instance show_label : Show Label :=
{|
  show lab := 
    match lab with
      | L => "L"
      | H => "H"
    end
|}.

Instance show_instruction : Show Instruction :=
{|
  show x := 
    match x with
      | Nop     => "Nop"
      | Push  n => "Push " ++ show n 
      | BCall n => "BCall " ++ show n
      | BRet    => "BRet"
      | Add     => "Add"
      | Load    => "Load"                    
      | Store   => "Store"
    end 
|}.

Fixpoint numed_contents {A : Type} (s : A -> string) (l : list A) (n : nat) 
: string :=
  match l with 
    | nil => ""%string
    | cons h t => show n ++ " : " ++ s h ++ nl ++ (numed_contents s t (S n))
  end.

Definition par (s : string) := "( " ++ s ++ " )".
   
Instance show_atom : Show Atom :=
{|
  show a :=
    let '(v @ l) := a in
    show v ++ " @ " ++ show l
|}.

Instance show_list {A : Type} `{_ : Show A} : Show (list A) :=
{|
  show l := numed_contents show l 0
|}.

Instance show_stack : Show Stack :=
{|
  show s := 
    let fix aux s := 
        match s with
          | a :: s' => show a ++ " : " ++ aux s'
          | a ::: s' => "R " ++ show a ++ " : " ++ aux s'
          | Mty => "[]"
        end
    in aux s
|}.


Class ShowPair (A : Type) : Type :=
{
  show_pair : A -> A -> string
}.

Definition show_variation (s1 s2 : string) :=
  "{ " ++ s1 ++ " / " ++ s2 ++ " }".

Instance show_int_pair : ShowPair Z :=
{|
  show_pair v1 v2 :=
    if Z.eqb v1 v2 then show v1 
    else show_variation (show v1) (show v2)
|}.

Instance show_label_pair : ShowPair Label :=
{|
  show_pair l1 l2 :=
    if label_eq l1 l2 then show l1
    else show_variation (show l1) (show l2)
|}.

Instance show_atom_pair : ShowPair Atom :=
{|
  show_pair a1 a2 :=
    let '(v1 @ l1) := a1 in
    let '(v2 @ l2) := a2 in
    show_pair v1 v1 ++ " @ " 
    ++ show_pair l1 l2
|}.

Instance show_mem_pair : ShowPair Mem :=
{|
  show_pair m1 m2 :=
    numed_contents (fun (xy : Atom * Atom) => 
                      let (x,y) := xy in show_pair x y) (combine m1 m2) 0
|}.

Fixpoint total_stack_length s := 
  match s with 
    | _ :: s' => S (total_stack_length s')
    | _ ::: s' => S (total_stack_length s')
    | _ => O
  end.

Instance show_stack_pair : ShowPair Stack :=
{|
  show_pair s1 s2 :=
    let len1 := total_stack_length s1 in
    let len2 := total_stack_length s2 in 
    let fix aux s1 s2 := 
        match s1, s2 with
          | a1::s1', a2::s2' => show_pair a1 a2 ++ " : " ++ aux s1' s2'
          | a1:::s1', a2:::s2' => "R " ++ show_pair a1 a2 ++ " : " ++ aux s1' s2'
          | Mty, Mty => "[]"
          | _, _ => show_variation (show s1) (show s2)
        end
    in aux s1 s2
|}.
            

Instance show_state_pair : ShowPair State :=
{|
  show_pair st1 st2 :=
    let '(St imem1 mem1 stk1 pc1) := st1 in
    let '(St imem2 mem2 stk2 pc2) := st2 in
    "Instructions: " ++ nl ++ show imem1 ++ nl ++
    "Memory: " ++ nl ++ show_pair mem1 mem2 ++ nl ++
    "Stack: " ++ nl ++ show_pair stk1 stk2 ++ nl ++
    "PC: " ++ show_pair pc1 pc2 ++ nl
|}.

Instance show_var {A} `{_ :ShowPair A} : Show (@Variation A) :=
{|
  show x := 
    let '(V x1 x2) := x in show_pair x1 x2
|}.