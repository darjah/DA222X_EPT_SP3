include "table.mzn";
include "alldifferent_except_0.mzn";
include "mz_data.dzn";
include "mz_testcase.dzn";
include "decreasing.mzn";

% tables
array[int, int] of int: ctc_ct_columns;
array[int, int] of int: node_rbb_swrev;
array[int, int] of int: rbb_capability;
array[int, int] of int: rbb_capability_nr_ports;
array[int, int] of int: rbb_compatibility;
array[int, int] of int: rbb_ru_swrev;
array[int, int] of int: rbb_topology;
array[int, int] of ru0: ru_combinations;
array[int, int] of int: ru_fb_bw_swrev;
array[int, int] of int: ru_port_pattern;
array[int, int] of int: ru_fb_ctc_allowed;
array[int, int] of int: ru_fb_ctc_data;

% predefined parameters
int: max_nodes_in_sol = 8;
int: max_rbbs_in_sol = 8;
int: max_radios_in_sol = 6;
int: max_radios_in_rbb = 4;
int: max_carriers_in_sol = card(CarrierSet);

% enums and sets with 0
enum pwr_mode;
set of int: pwr_mode0 = 0..max(pwr_mode);
enum rbb;
set of int: rbb0 = 0..max(rbb);
enum node;
set of int: node0 = 0..max(node);
enum ru;
set of int: ru0 = 0..max(ru);
enum bw;
int: BW_NONE = 0;
set of int: bw0 = 0..max(bw);
enum freq_band;
enum carrier_type;
enum ctc;
set of int: ctc0 = 0..max(ctc);
enum port_pattern;
enum port_name;
enum carrier_params = {FREQ_BAND, CARRIER_TYPE, NR_TX, NR_RX, BW, OUT_PWR};
array[int, int] of int: carriers;
set of int: CarrierSet = index_set_1of2(carriers);
set of int: RadioSet = index_set(radios);
% decision variables
var 141..500: swrev;

var 1..max_nodes_in_sol: nr_selected_nodes;
var 1..max_rbbs_in_sol: nr_selected_rbbs;
var 1..max_radios_in_sol: nr_selected_radios;

array[1..max_nodes_in_sol] of var node0: nodes;
array[1..max_rbbs_in_sol] of var rbb0: rbbs;
array[1..max_radios_in_sol] of var ru0: radios;

array[1..max_rbbs_in_sol] of var 0..max_nodes_in_sol: rbbs_in_nodes;
/*
radios_in_rbb:
[|1,  2,  0,  0
 |2,  0,  0,  0]
*/
array[1..max_rbbs_in_sol, 1..max_radios_in_rbb] of var 0..max_radios_in_sol: radios_in_rbb;
/*
radio_index_in_rbb:
[|1,  2,  0,  0,  0,  0 
 |0,  1,  0,  0,  0,  0 ]
*/
array[1..max_rbbs_in_sol, 1..max_radios_in_sol] of var 0..max_radios_in_rbb: radio_index_in_rbb;

array[1..max_carriers_in_sol] of var rbb0: carrier_rbb_allocation;
array[1..max_carriers_in_sol, 1..max_rbbs_in_sol, 1..8] of var 0..1: carrier_tx_allocation;
array[1..max_carriers_in_sol, 1..max_rbbs_in_sol, 1..8] of var 0..1: carrier_rx_allocation;

array[1..max_radios_in_sol] of var ctc0: radio_ctc;
/*---------------------------------------------------------------------------------------*/

% x with idx lesser than selected nr x must be greater than 0
constraint forall(i in 1..max_nodes_in_sol) (i <= nr_selected_nodes -> nodes[i] > 0);
constraint forall(i in 1..max_rbbs_in_sol) (i <= nr_selected_rbbs -> rbbs[i] > 0);
constraint forall(i in 1..max_radios_in_sol) (i <= nr_selected_radios -> radios[i] > 0);
constraint forall(i in 1..max_rbbs_in_sol) (i <= nr_selected_rbbs -> rbbs_in_nodes[i] > 0);

% x in solution with idx greater than nr selected x set to 0
constraint forall(i in 2..max_nodes_in_sol) (i > nr_selected_nodes -> nodes[i] = 0);
constraint forall(i in 2..max_rbbs_in_sol) (i > nr_selected_rbbs -> rbbs[i] = 0);
constraint forall(i in 2..max_radios_in_sol) (i > nr_selected_radios -> radios[i] = 0);
constraint forall(i in 1..max_rbbs_in_sol) (i > nr_selected_rbbs -> rbbs_in_nodes[i] = 0);

% each selected rbb must be connected to a node and that node must have an idx less than nr selected nodes
constraint forall(i in 1..nr_selected_rbbs) 
                  (rbbs_in_nodes[i] > 0 /\ rbbs_in_nodes[i] <= nr_selected_nodes);

% compatibility check: each rbb is connected to a compatible node
constraint forall(i in 1..nr_selected_rbbs) 
  ( let{ var int: min_swrev } in
                 (table([nodes[rbbs_in_nodes[i]], rbbs[i], min_swrev], node_rbb_swrev) /\
                 min_swrev <= swrev));

% one rbb cannot be connected to the same radio (idx) more than once
constraint forall(i in 1..max_rbbs_in_sol) 
                 ( alldifferent_except_0( [radios_in_rbb[i, j] | j in 1..max_radios_in_rbb] ) );

% each rbb must be connected to exactly x radios
constraint forall(r in 1..nr_selected_rbbs) 
                 ( table([rbbs[r], sum( i in 1..max_radios_in_rbb ) ( radios_in_rbb[r, i] > 0 )], rbb_topology ));

%-------                 
% ha kvar dessa så att man använder alla r i radios i något av rbb:erna
% each radio in each rbb must be in the array of radios
constraint forall( r in 1..nr_selected_radios ) 
                 ( exists( i in 1..max_rbbs_in_sol, j in 1..max_radios_in_rbb ) ( radios_in_rbb[i,j] = r ));

% each radio in each rbb must be in the array of selected radios or 0
constraint forall( i in 1..max_rbbs_in_sol, j in 1..max_radios_in_rbb ) 
                 ( exists( r in 1..nr_selected_radios ) ( radios_in_rbb[i,j] = r \/ radios_in_rbb[i,j] = 0 )); 
%-------

% compatibility check: each radio in each rbb is compatible with that rbb
constraint forall(i in 1..max_rbbs_in_sol, j in 1..max_radios_in_rbb) 
  ( let{ var int: min_swrev } in
                  (radios_in_rbb[i,j] > 0 -> table([rbbs[i], radios[j], min_swrev], rbb_ru_swrev) /\
                  min_swrev <= swrev) );

% compatibility check: all radios in each rbb is ordered according to table of valid combinations and specific order
constraint forall(i in 1..nr_selected_rbbs) 
                  (table([if radios_in_rbb[i,j] = 0 
                          then 0 
                          else radios[radios_in_rbb[i,j]] endif | j in 1..max_radios_in_rbb], ru_combinations));

%inverse_set
constraint forall( i in 1..max_rbbs_in_sol, j in 1..max_radios_in_rbb ) 
                 ( radios_in_rbb[i, j] > 0 -> radio_index_in_rbb[i, radios_in_rbb[i, j]] = j );
                
constraint forall( i in 1..max_rbbs_in_sol, j in 1..max_radios_in_sol) 
                 ( radio_index_in_rbb[i, j] > 0 -> radios_in_rbb[i, radio_index_in_rbb[i, j]] = j);

% each pairwise combination of rbbs and radios are compatible
constraint forall( r1 in 1..max_rbbs_in_sol, r2 in 1..max_rbbs_in_sol where r1 != r2) 
                 ( exists( i in 1..max_radios_in_sol ) ( ( radio_index_in_rbb[r1, i] > 0 /\ radio_index_in_rbb[r2, i] > 0 ) -> 
                   table( [rbb[r1], radio_index_in_rbb[r1, i], rbb[r2], radio_index_in_rbb[r2, i]], rbb_compatibility ) ) );

% each carrier must be allocated to (exactly) one rbb
constraint forall ( c in CarrierSet )( carrier_rbb_allocation[c] != 0 );

% no more connections to rbbs than we have carriers
constraint forall ( c in 1..max_carriers_in_sol where c > max(CarrierSet) )( carrier_rbb_allocation[c] = 0 );

% each rbb in the solution must have at least one carrier
constraint forall ( r in 1..max_rbbs_in_sol where rbbs[r] > 0 ) ( exists( c in CarrierSet ) ( carrier_rbb_allocation[c] = r ) );

% number of tx connections must be equal to NR_TX branches specified on the carrier
constraint forall ( c in CarrierSet ) 
                  ( sum ( i in 1..8 )( carrier_tx_allocation[c, carrier_rbb_allocation[c], i] ) = carriers[c, NR_TX] );
% number of rx connections must be equal to NR_RX branches specified on the carrier
constraint forall ( c in CarrierSet ) 
                  ( sum ( i in 1..8 )( carrier_rx_allocation[c, carrier_rbb_allocation[c], i] ) = carriers[c, NR_RX] );

% each carrier is connected to a rbb that is connected to a radio that support those carrier demands
constraint forall( c in CarrierSet )
  ( let { var int: rbb_ru_idx, 
          var int: min_sw_rev } in 
  table( 
      [radios[radios_in_rbb[carrier_rbb_allocation[c], rbb_ru_idx]], carriers[c, FREQ_BAND], carriers[c, BW], min_sw_rev],
      ru_fb_bw_swrev ) /\
  swrev >= min_sw_rev );
                              
% for each carrier, connected to an rbb, that port on that rbb must be tx/rx compatible 
constraint forall ( c in CarrierSet, p in 1..8 )
( let { var int: tx_capable,
        var int: rx_capable,
        var int: ru_idx,
        var int: port_name,
        var int: port_pattern,
        var int: ru_tx_capable,
        var int: ru_rx_capable }
  in ( table( [rbbs[carrier_rbb_allocation[c]], p, tx_capable, rx_capable, radios_in_rbb[carrier_rbb_allocation[c], ru_idx], port_name], rbb_capability ) /\
          carrier_tx_allocation[c, carrier_rbb_allocation[c], p] <= tx_capable /\
          carrier_rx_allocation[c, carrier_rbb_allocation[c], p] <= rx_capable /\
       table( [radios[radios_in_rbb[carrier_rbb_allocation[c], ru_idx]], 
               carriers[c, FREQ_BAND], 
               radio_pwr_modes[radios_in_rbb[carrier_rbb_allocation[c], ru_idx]], 
               port_pattern, 
               port_name, 
               ru_tx_capable, 
               ru_rx_capable ], ru_port_pattern ) /\
          carrier_tx_allocation[c, carrier_rbb_allocation[c], p] <= ru_tx_capable /\
          carrier_rx_allocation[c, carrier_rbb_allocation[c], p] <= ru_rx_capable ) );


array[1..max_radios_in_sol] of var pwr_mode0: radio_pwr_modes;
%constraint forall(r in RadioSet) (radio_pwr_modes[r] > 0);
%constraint forall(r in 1..max_radios_in_sol where r > nr_selected_radios) (radio_pwr_modes[r] = 0);

%array[1..max_radios_in_sol] of var rpp0: radio_port_patterns;
constraint decreasing(radios);

/*
[c1,2,3,4
| 1, 0, 1, 0
| 0, 1, 0, 0
| 0, 0, 0, 1
*/
array[1..max_radios_in_sol, 1..max_carriers_in_sol] of var int: radio_carriers;
%constraint forall(c in CarrierSet, i in 1..max_radios_in_rbb) ( radio_carriers[radios_in_rbb[carrier_rbb_allocation[c], i], c] = (radios_in_rbb[carrier_rbb_allocation[c], i] > 0));
    
% radio and ctc constraints
constraint forall(i in 1.. max_radios_in_sol where i <= nr_selected_radios) (radio_ctc[i] > 0);
constraint forall(i in 1.. max_radios_in_sol where i > nr_selected_radios) (radio_ctc[i] = 0);


%constraint forall(r in RadioSet) (table([radio_ctc[r], carriers[c, CARRIER_TYPE]], ctc_ct_columns);

constraint forall(c in CarrierSet) %TODO: 
  ( let { var int: min_sw_rev,
          var int: ru_idx } in 
  table([radios[radios_in_rbb[carrier_rbb_allocation[c], ru_idx]], carriers[c, FREQ_BAND], radio_ctc[radios_in_rbb[carrier_rbb_allocation[c], ru_idx]], min_sw_rev], ru_fb_ctc_allowed) /\
  swrev >= min_sw_rev );

/*---------------------------------------------------------------------------------------*/

solve satisfy;

output["swrev = \(swrev)\n",
       "nr_selected_nodes = \(nr_selected_nodes)\n",
       "nr_selected_radios = \(nr_selected_radios)\n",
       "nr_selected_rbbs = \(nr_selected_rbbs)\n",
       "nodes = ["] ++ 
       [if fix(nodes[i]) != 0 then show(to_enum(node, nodes[i])) ++ ", " else "" endif | i in 1..max_nodes_in_sol] ++ ["]\n"] ++
       ["rbbs in nodes = [" ] ++
       [if fix(rbbs_in_nodes[i]) != 0 then show(rbbs_in_nodes[i]) ++ ", " else "" endif | i in 1..max_nodes_in_sol] ++ ["]\n"] ++
       ["rbbs = ["] ++ 
       [if fix(rbbs[i]) != 0 then show(to_enum(rbb, rbbs[i])) ++ ", " else "" endif | i in 1..max_rbbs_in_sol] ++ ["]\n"] ++
       ["radios = ["] ++ 
       [if fix(radios[i]) != 0 then show(to_enum(ru, radios[i])) ++ ", " else "" endif | i in 1..max_radios_in_sol] ++ ["]\n"] ++
       ["radio pwr modes = ["] ++
       [if fix(radio_pwr_modes[i]) != 0 then show(to_enum(pwr_mode, radio_pwr_modes[i])) ++ ", " else "" endif | i in 1..max_radios_in_sol] ++ ["]\n"] ++ 
       ["radios CTC = ["] ++ 
       [if fix(radio_ctc[i]) != 0 then show(to_enum(ctc, radio_ctc[i])) ++ ", " else "" endif | i in 1..max_radios_in_sol] ++ ["]\n"] ++
       ["radios in rbb = [\n"] ++ 
       [if j = 1 then "|" else "" endif ++ 
          if fix(radios_in_rbb[i,j]) != 0 then show(to_enum(ru, radios[radios_in_rbb[i,j]])) ++ ", " else "0, " endif ++ 
          if j = max_radios_in_rbb then "\n" else "" endif 
             | i in 1..max_rbbs_in_sol, j in 1..max_radios_in_rbb] ++ ["]\n"] ++ 
       ["radio index in rbb = [\n"] ++ 
       [if j = 1 then "|" else "" endif ++ 
          if j < max_radios_in_sol then show(radio_index_in_rbb[i, j]) ++ ", " else show(radio_index_in_rbb[i, j]) ++ "\n" endif 
             | i in 1..max_rbbs_in_sol, j in 1..max_radios_in_sol] ++ ["]\n"] ++
       [if i = 1 then "c\(c), rbb\(carrier_rbb_allocation[c]) = \n " ++ "tx/rx allocation = [" else "" endif ++
        show(carrier_tx_allocation[c, carrier_rbb_allocation[c], i ]) ++ 
        show(carrier_rx_allocation[c, carrier_rbb_allocation[c], i ]) ++
        if i < 8 then ", " else "]\n" endif | c in CarrierSet, i in 1..8] ++ ["\n"];
