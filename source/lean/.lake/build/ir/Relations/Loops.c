// Lean compiler output
// Module: Relations.Loops
// Imports: Init
#include <lean/lean.h>
#if defined(__clang__)
#pragma clang diagnostic ignored "-Wunused-parameter"
#pragma clang diagnostic ignored "-Wunused-label"
#elif defined(__GNUC__) && !defined(__CLANG__)
#pragma GCC diagnostic ignored "-Wunused-parameter"
#pragma GCC diagnostic ignored "-Wunused-label"
#pragma GCC diagnostic ignored "-Wunused-but-set-variable"
#endif
#ifdef __cplusplus
extern "C" {
#endif
LEAN_EXPORT lean_object* l_Relations_Loops_unite___boxed(lean_object*, lean_object*, lean_object*);
static lean_object* l_Relations_Loops_name___closed__1;
extern lean_object* l_instInhabitedNat;
static lean_object* l_Relations_Loops_create___closed__1;
lean_object* l_Array_range___lambda__1___boxed(lean_object*);
lean_object* l_Array_ofFn___rarg(lean_object*, lean_object*);
LEAN_EXPORT lean_object* l_Relations_Loops_set__count(lean_object*);
uint8_t lean_nat_dec_eq(lean_object*, lean_object*);
LEAN_EXPORT lean_object* l_Relations_Loops_reset___rarg(lean_object*);
lean_object* lean_array_set(lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* l_Relations_Loops_set__count___boxed(lean_object*);
LEAN_EXPORT lean_object* l_Relations_Loops_name;
LEAN_EXPORT lean_object* l_Relations_Loops_create(lean_object*);
LEAN_EXPORT lean_object* l_Relations_Loops_reset(lean_object*);
LEAN_EXPORT lean_object* l_Relations_Loops_unite(lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* l_Relations_Loops_reset___boxed(lean_object*);
lean_object* lean_array_get(lean_object*, lean_object*, lean_object*);
lean_object* lean_nat_add(lean_object*, lean_object*);
static lean_object* _init_l_Relations_Loops_name___closed__1() {
_start:
{
lean_object* x_1; 
x_1 = lean_mk_string_unchecked("Loops", 5, 5);
return x_1;
}
}
static lean_object* _init_l_Relations_Loops_name() {
_start:
{
lean_object* x_1; 
x_1 = l_Relations_Loops_name___closed__1;
return x_1;
}
}
static lean_object* _init_l_Relations_Loops_create___closed__1() {
_start:
{
lean_object* x_1; 
x_1 = lean_alloc_closure((void*)(l_Array_range___lambda__1___boxed), 1, 0);
return x_1;
}
}
LEAN_EXPORT lean_object* l_Relations_Loops_create(lean_object* x_1) {
_start:
{
lean_object* x_2; lean_object* x_3; lean_object* x_4; lean_object* x_5; 
x_2 = l_Relations_Loops_create___closed__1;
x_3 = l_Array_ofFn___rarg(x_1, x_2);
x_4 = lean_unsigned_to_nat(0u);
x_5 = lean_alloc_ctor(0, 2, 0);
lean_ctor_set(x_5, 0, x_3);
lean_ctor_set(x_5, 1, x_4);
return x_5;
}
}
LEAN_EXPORT lean_object* l_Relations_Loops_reset___rarg(lean_object* x_1) {
_start:
{
lean_object* x_2; lean_object* x_3; lean_object* x_4; lean_object* x_5; 
x_2 = l_Relations_Loops_create___closed__1;
x_3 = l_Array_ofFn___rarg(x_1, x_2);
x_4 = lean_unsigned_to_nat(0u);
x_5 = lean_alloc_ctor(0, 2, 0);
lean_ctor_set(x_5, 0, x_3);
lean_ctor_set(x_5, 1, x_4);
return x_5;
}
}
LEAN_EXPORT lean_object* l_Relations_Loops_reset(lean_object* x_1) {
_start:
{
lean_object* x_2; 
x_2 = lean_alloc_closure((void*)(l_Relations_Loops_reset___rarg), 1, 0);
return x_2;
}
}
LEAN_EXPORT lean_object* l_Relations_Loops_reset___boxed(lean_object* x_1) {
_start:
{
lean_object* x_2; 
x_2 = l_Relations_Loops_reset(x_1);
lean_dec(x_1);
return x_2;
}
}
LEAN_EXPORT lean_object* l_Relations_Loops_unite(lean_object* x_1, lean_object* x_2, lean_object* x_3) {
_start:
{
uint8_t x_4; 
x_4 = !lean_is_exclusive(x_1);
if (x_4 == 0)
{
lean_object* x_5; lean_object* x_6; lean_object* x_7; lean_object* x_8; lean_object* x_9; uint8_t x_10; 
x_5 = lean_ctor_get(x_1, 0);
x_6 = lean_ctor_get(x_1, 1);
x_7 = l_instInhabitedNat;
x_8 = lean_array_get(x_7, x_5, x_2);
x_9 = lean_array_get(x_7, x_5, x_3);
x_10 = lean_nat_dec_eq(x_8, x_3);
if (x_10 == 0)
{
lean_object* x_11; lean_object* x_12; 
lean_inc(x_9);
x_11 = lean_array_set(x_5, x_8, x_9);
x_12 = lean_array_set(x_11, x_9, x_8);
lean_dec(x_9);
lean_ctor_set(x_1, 0, x_12);
return x_1;
}
else
{
lean_object* x_13; lean_object* x_14; 
lean_dec(x_9);
lean_dec(x_8);
x_13 = lean_unsigned_to_nat(1u);
x_14 = lean_nat_add(x_6, x_13);
lean_dec(x_6);
lean_ctor_set(x_1, 1, x_14);
return x_1;
}
}
else
{
lean_object* x_15; lean_object* x_16; lean_object* x_17; lean_object* x_18; lean_object* x_19; uint8_t x_20; 
x_15 = lean_ctor_get(x_1, 0);
x_16 = lean_ctor_get(x_1, 1);
lean_inc(x_16);
lean_inc(x_15);
lean_dec(x_1);
x_17 = l_instInhabitedNat;
x_18 = lean_array_get(x_17, x_15, x_2);
x_19 = lean_array_get(x_17, x_15, x_3);
x_20 = lean_nat_dec_eq(x_18, x_3);
if (x_20 == 0)
{
lean_object* x_21; lean_object* x_22; lean_object* x_23; 
lean_inc(x_19);
x_21 = lean_array_set(x_15, x_18, x_19);
x_22 = lean_array_set(x_21, x_19, x_18);
lean_dec(x_19);
x_23 = lean_alloc_ctor(0, 2, 0);
lean_ctor_set(x_23, 0, x_22);
lean_ctor_set(x_23, 1, x_16);
return x_23;
}
else
{
lean_object* x_24; lean_object* x_25; lean_object* x_26; 
lean_dec(x_19);
lean_dec(x_18);
x_24 = lean_unsigned_to_nat(1u);
x_25 = lean_nat_add(x_16, x_24);
lean_dec(x_16);
x_26 = lean_alloc_ctor(0, 2, 0);
lean_ctor_set(x_26, 0, x_15);
lean_ctor_set(x_26, 1, x_25);
return x_26;
}
}
}
}
LEAN_EXPORT lean_object* l_Relations_Loops_unite___boxed(lean_object* x_1, lean_object* x_2, lean_object* x_3) {
_start:
{
lean_object* x_4; 
x_4 = l_Relations_Loops_unite(x_1, x_2, x_3);
lean_dec(x_3);
lean_dec(x_2);
return x_4;
}
}
LEAN_EXPORT lean_object* l_Relations_Loops_set__count(lean_object* x_1) {
_start:
{
lean_object* x_2; 
x_2 = lean_ctor_get(x_1, 1);
lean_inc(x_2);
return x_2;
}
}
LEAN_EXPORT lean_object* l_Relations_Loops_set__count___boxed(lean_object* x_1) {
_start:
{
lean_object* x_2; 
x_2 = l_Relations_Loops_set__count(x_1);
lean_dec(x_1);
return x_2;
}
}
lean_object* initialize_Init(uint8_t builtin, lean_object*);
static bool _G_initialized = false;
LEAN_EXPORT lean_object* initialize_Relations_Loops(uint8_t builtin, lean_object* w) {
lean_object * res;
if (_G_initialized) return lean_io_result_mk_ok(lean_box(0));
_G_initialized = true;
res = initialize_Init(builtin, lean_io_mk_world());
if (lean_io_result_is_error(res)) return res;
lean_dec_ref(res);
l_Relations_Loops_name___closed__1 = _init_l_Relations_Loops_name___closed__1();
lean_mark_persistent(l_Relations_Loops_name___closed__1);
l_Relations_Loops_name = _init_l_Relations_Loops_name();
lean_mark_persistent(l_Relations_Loops_name);
l_Relations_Loops_create___closed__1 = _init_l_Relations_Loops_create___closed__1();
lean_mark_persistent(l_Relations_Loops_create___closed__1);
return lean_io_result_mk_ok(lean_box(0));
}
#ifdef __cplusplus
}
#endif
