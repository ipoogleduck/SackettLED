/* This file was generated by upbc (the upb compiler) from the input
 * file:
 *
 *     google/api/expr/v1alpha1/eval.proto
 *
 * Do not edit -- your changes will be discarded when the file is
 * regenerated. */

#include "upb/def.h"
#include "google/api/expr/v1alpha1/eval.upbdefs.h"
#include "google/api/expr/v1alpha1/eval.upb.h"

extern upb_def_init google_api_expr_v1alpha1_value_proto_upbdefinit;
extern upb_def_init google_rpc_status_proto_upbdefinit;
static const char descriptor[738] = {'\n', '#', 'g', 'o', 'o', 'g', 'l', 'e', '/', 'a', 'p', 'i', '/', 'e', 'x', 'p', 'r', '/', 'v', '1', 'a', 'l', 'p', 'h', 'a', 
'1', '/', 'e', 'v', 'a', 'l', '.', 'p', 'r', 'o', 't', 'o', '\022', '\030', 'g', 'o', 'o', 'g', 'l', 'e', '.', 'a', 'p', 'i', '.', 
'e', 'x', 'p', 'r', '.', 'v', '1', 'a', 'l', 'p', 'h', 'a', '1', '\032', '$', 'g', 'o', 'o', 'g', 'l', 'e', '/', 'a', 'p', 'i', 
'/', 'e', 'x', 'p', 'r', '/', 'v', '1', 'a', 'l', 'p', 'h', 'a', '1', '/', 'v', 'a', 'l', 'u', 'e', '.', 'p', 'r', 'o', 't', 
'o', '\032', '\027', 'g', 'o', 'o', 'g', 'l', 'e', '/', 'r', 'p', 'c', '/', 's', 't', 'a', 't', 'u', 's', '.', 'p', 'r', 'o', 't', 
'o', '\"', '\302', '\001', '\n', '\t', 'E', 'v', 'a', 'l', 'S', 't', 'a', 't', 'e', '\022', ';', '\n', '\006', 'v', 'a', 'l', 'u', 'e', 's', 
'\030', '\001', ' ', '\003', '(', '\013', '2', '#', '.', 'g', 'o', 'o', 'g', 'l', 'e', '.', 'a', 'p', 'i', '.', 'e', 'x', 'p', 'r', '.', 
'v', '1', 'a', 'l', 'p', 'h', 'a', '1', '.', 'E', 'x', 'p', 'r', 'V', 'a', 'l', 'u', 'e', 'R', '\006', 'v', 'a', 'l', 'u', 'e', 
's', '\022', 'D', '\n', '\007', 'r', 'e', 's', 'u', 'l', 't', 's', '\030', '\003', ' ', '\003', '(', '\013', '2', '*', '.', 'g', 'o', 'o', 'g', 
'l', 'e', '.', 'a', 'p', 'i', '.', 'e', 'x', 'p', 'r', '.', 'v', '1', 'a', 'l', 'p', 'h', 'a', '1', '.', 'E', 'v', 'a', 'l', 
'S', 't', 'a', 't', 'e', '.', 'R', 'e', 's', 'u', 'l', 't', 'R', '\007', 'r', 'e', 's', 'u', 'l', 't', 's', '\032', '2', '\n', '\006', 
'R', 'e', 's', 'u', 'l', 't', '\022', '\022', '\n', '\004', 'e', 'x', 'p', 'r', '\030', '\001', ' ', '\001', '(', '\003', 'R', '\004', 'e', 'x', 'p', 
'r', '\022', '\024', '\n', '\005', 'v', 'a', 'l', 'u', 'e', '\030', '\002', ' ', '\001', '(', '\003', 'R', '\005', 'v', 'a', 'l', 'u', 'e', '\"', '\312', 
'\001', '\n', '\t', 'E', 'x', 'p', 'r', 'V', 'a', 'l', 'u', 'e', '\022', '7', '\n', '\005', 'v', 'a', 'l', 'u', 'e', '\030', '\001', ' ', '\001', 
'(', '\013', '2', '\037', '.', 'g', 'o', 'o', 'g', 'l', 'e', '.', 'a', 'p', 'i', '.', 'e', 'x', 'p', 'r', '.', 'v', '1', 'a', 'l', 
'p', 'h', 'a', '1', '.', 'V', 'a', 'l', 'u', 'e', 'H', '\000', 'R', '\005', 'v', 'a', 'l', 'u', 'e', '\022', ':', '\n', '\005', 'e', 'r', 
'r', 'o', 'r', '\030', '\002', ' ', '\001', '(', '\013', '2', '\"', '.', 'g', 'o', 'o', 'g', 'l', 'e', '.', 'a', 'p', 'i', '.', 'e', 'x', 
'p', 'r', '.', 'v', '1', 'a', 'l', 'p', 'h', 'a', '1', '.', 'E', 'r', 'r', 'o', 'r', 'S', 'e', 't', 'H', '\000', 'R', '\005', 'e', 
'r', 'r', 'o', 'r', '\022', '@', '\n', '\007', 'u', 'n', 'k', 'n', 'o', 'w', 'n', '\030', '\003', ' ', '\001', '(', '\013', '2', '$', '.', 'g', 
'o', 'o', 'g', 'l', 'e', '.', 'a', 'p', 'i', '.', 'e', 'x', 'p', 'r', '.', 'v', '1', 'a', 'l', 'p', 'h', 'a', '1', '.', 'U', 
'n', 'k', 'n', 'o', 'w', 'n', 'S', 'e', 't', 'H', '\000', 'R', '\007', 'u', 'n', 'k', 'n', 'o', 'w', 'n', 'B', '\006', '\n', '\004', 'k', 
'i', 'n', 'd', '\"', '6', '\n', '\010', 'E', 'r', 'r', 'o', 'r', 'S', 'e', 't', '\022', '*', '\n', '\006', 'e', 'r', 'r', 'o', 'r', 's', 
'\030', '\001', ' ', '\003', '(', '\013', '2', '\022', '.', 'g', 'o', 'o', 'g', 'l', 'e', '.', 'r', 'p', 'c', '.', 'S', 't', 'a', 't', 'u', 
's', 'R', '\006', 'e', 'r', 'r', 'o', 'r', 's', '\"', '\"', '\n', '\n', 'U', 'n', 'k', 'n', 'o', 'w', 'n', 'S', 'e', 't', '\022', '\024', 
'\n', '\005', 'e', 'x', 'p', 'r', 's', '\030', '\001', ' ', '\003', '(', '\003', 'R', '\005', 'e', 'x', 'p', 'r', 's', 'B', 'l', '\n', '\034', 'c', 
'o', 'm', '.', 'g', 'o', 'o', 'g', 'l', 'e', '.', 'a', 'p', 'i', '.', 'e', 'x', 'p', 'r', '.', 'v', '1', 'a', 'l', 'p', 'h', 
'a', '1', 'B', '\t', 'E', 'v', 'a', 'l', 'P', 'r', 'o', 't', 'o', 'P', '\001', 'Z', '<', 'g', 'o', 'o', 'g', 'l', 'e', '.', 'g', 
'o', 'l', 'a', 'n', 'g', '.', 'o', 'r', 'g', '/', 'g', 'e', 'n', 'p', 'r', 'o', 't', 'o', '/', 'g', 'o', 'o', 'g', 'l', 'e', 
'a', 'p', 'i', 's', '/', 'a', 'p', 'i', '/', 'e', 'x', 'p', 'r', '/', 'v', '1', 'a', 'l', 'p', 'h', 'a', '1', ';', 'e', 'x', 
'p', 'r', '\370', '\001', '\001', 'b', '\006', 'p', 'r', 'o', 't', 'o', '3', 
};

static upb_def_init *deps[3] = {
  &google_api_expr_v1alpha1_value_proto_upbdefinit,
  &google_rpc_status_proto_upbdefinit,
  NULL
};

upb_def_init google_api_expr_v1alpha1_eval_proto_upbdefinit = {
  deps,
  &google_api_expr_v1alpha1_eval_proto_upb_file_layout,
  "google/api/expr/v1alpha1/eval.proto",
  UPB_STRVIEW_INIT(descriptor, 738)
};
