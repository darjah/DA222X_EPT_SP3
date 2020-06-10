%constraint rbbs[1] = RBB44_1D;
%constraint radios[1] = KRC118702R1;

include "table.mzn";
include "alldifferent_except_0.mzn";

% tables
array[int, int] of int: node_rbb_swrev;
array[int, int] of int: rbb_ru;
array[int, int] of int: rbb_capability;
array[int, int] of int: rbb_capability_nr_ports;
array[int, int] of int: rbb_compatibility;
array[int, int] of int: rbb_topology;
array[int, int] of int: ru_fb_bw_swrev;
array[int, int] of ru0: ru_combinations;

% predefined parameters
int: max_nodes_in_sol = 8;
int: max_rbbs_in_sol = 8;
int: max_radios_in_sol = 6;
int: max_radios_in_rbb = 4;
int: max_carriers_in_sol = 8;

% enums and sets with 0
enum rbb;
set of int: rbb0 = 0..max(rbb);
enum node;
set of int: node0 = 0..max(node);
enum ru;
set of int: ru0 = 0..max(ru);

enum freq_band;
enum carrier_type;
enum bw;
set of int: bw0 = 0..max(bw);
enum carrier_params = {FREQ_BAND, CARRIER_TYPE, NR_TX, NR_RX, BW, OUT_PWR};
array[int, int] of int: carriers;

array[1..max_carriers_in_sol] of var rbb0: carrier_rbb_allocation;
array[1..max_carriers_in_sol, 1..max_rbbs_in_sol, 1..8] of var 0..1: carrier_tx_allocation;
array[1..max_carriers_in_sol, 1..max_rbbs_in_sol, 1..8] of var 0..1: carrier_rx_allocation;

constraint forall ( c in CarrierSet ) ( sum ( i in 1..8 )( carrier_tx_allocation[c, carrier_rbb_allocation[c], i] ) = carriers[c, NR_TX]);
constraint forall ( c in CarrierSet ) ( sum ( i in 1..8 )( carrier_rx_allocation[c, carrier_rbb_allocation[c], i] ) = carriers[c, NR_RX]);
constraint forall ( c in CarrierSet ) ( carrier_rbb_allocation[c] != 0);
constraint forall ( c in 1..max_carriers_in_sol where c > max(CarrierSet)) (carrier_rbb_allocation[c] = 0);
set of int: CarrierSet = index_set_1of2(carriers);

constraint forall (c in CarrierSet, p in 1..rbb_port_qty(rbbs[carrier_rbb_allocation[c]]))
( let { var int: tx_capable,
        var int: rx_capable
      }
  in table([rbbs[carrier_rbb_allocation[c]], p, tx_capable, rx_capable]
          , rbb_capability
          ) /\
     carrier_tx_allocation[c, carrier_rbb_allocation[c], p] <= tx_capable /\
     carrier_rx_allocation[c, carrier_rbb_allocation[c], p] <= rx_capable
);

% decision variables
var int: swrev;

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

/*---------------------------------------------------------------------------------------*/

%inverse_set
constraint forall(i in 1..max_rbbs_in_sol, j in 1..max_radios_in_rbb) 
                 (radios_in_rbb[i, j] > 0 -> radio_index_in_rbb[i, radios_in_rbb[i, j]] = j);
                
constraint forall(i in 1..max_rbbs_in_sol, j in 1..max_radios_in_sol) 
                 (radio_index_in_rbb[i, j] > 0 -> radios_in_rbb[i, radio_index_in_rbb[i, j]] = j);

% each pairwise combination of rbbs and radios compatible according to table
constraint forall(r1 in 1..max_rbbs_in_sol, r2 in 1..max_rbbs_in_sol where r1 != r2) 
                (exists(i in 1..max_radios_in_sol) ((radio_index_in_rbb[r1, i] > 0 /\ radio_index_in_rbb[r2, i] > 0) -> 
                    table([rbb[r1], radio_index_in_rbb[r1, i], rbb[r2], radio_index_in_rbb[r2, i]], rbb_compatibility)));

% x with idx lesser than selected nr x must be greater than 0
constraint forall(i in 1..max_nodes_in_sol) (i <= nr_selected_nodes -> nodes[i] > 0);
constraint forall(i in 1..max_rbbs_in_sol) (i <= nr_selected_rbbs -> rbbs[i] > 0);
constraint forall(i in 1..max_radios_in_sol) (i <= nr_selected_radios -> radios[i] > 0);

% x in solution with idx greater than nr selected x set to 0
constraint forall(i in 2..max_nodes_in_sol) (i > nr_selected_nodes -> nodes[i] = 0);
constraint forall(i in 2..max_rbbs_in_sol) (i > nr_selected_rbbs -> rbbs[i] = 0);
constraint forall(i in 2..max_radios_in_sol) (i > nr_selected_radios -> radios[i] = 0);

% each selected rbb must be connected to a node and that node must have an idx less than nr selected nodes
constraint forall(i in 1..nr_selected_rbbs) 
                  (rbbs_in_nodes[i] > 0 /\ rbbs_in_nodes[i] <= nr_selected_nodes);

% 
constraint forall(i in 1..max_rbbs_in_sol) (i > nr_selected_rbbs -> rbbs_in_nodes[i] = 0);

% compatibility check: each rbb is connected to a compatible node
constraint forall(i in 1..nr_selected_rbbs) 
                  (table([nodes[rbbs_in_nodes[i]], rbbs[i], swrev], node_rbb_swrev));

% one rbb cannot be connected to the same radio (idx) more than once
constraint forall(i in 1..max_rbbs_in_sol) 
                  (alldifferent_except_0([radios_in_rbb[i, j] | j in 1..max_radios_in_rbb]));

% each rbb must be connected to exactly x radios
constraint forall(r in 1..nr_selected_rbbs) 
                  (table([rbbs[r], sum(i in 1..max_radios_in_rbb)(radios_in_rbb[r, i] > 0)], rbb_topology));

%-------                 
% ha kvar dessa så att man använder alla r i radios i något av rbb:erna
% each radio in each rbb must be in the array of radios
constraint forall(r in 1..nr_selected_radios) (exists(i in 1..max_rbbs_in_sol, j in 1..max_radios_in_rbb) (radios_in_rbb[i,j] = r));

% each radio in each rbb must be in the array of selected radios or 0
constraint forall(i in 1..max_rbbs_in_sol, j in 1..max_radios_in_rbb) 
                 (exists(r in 1..nr_selected_radios) (radios_in_rbb[i,j] = r \/ radios_in_rbb[i,j] = 0)); 
%-------

% compatibility check: each radio in each rbb is compatible with that rbb
constraint forall(i in 1..max_rbbs_in_sol, j in 1..max_radios_in_rbb) 
                  (radios_in_rbb[i,j] > 0 -> table([rbbs[i], radios[j]], rbb_ru));

% compatibility check: all radios in each rbb is ordered according to table of valid combinations and specific order
constraint forall(i in 1..nr_selected_rbbs) 
                  (table([if radios_in_rbb[i,j] = 0 
                          then 0 
                          else radios[radios_in_rbb[i,j]] endif | j in 1..max_radios_in_rbb], ru_combinations));
                          
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
       ["radios in rbb = [\n"] ++ 
       [if j = 1 then "|" else "" endif ++ 
          if fix(radios_in_rbb[i,j]) != 0 then show(to_enum(ru, radios[radios_in_rbb[i,j]])) ++ ", " else "0, " endif ++ 
          if j = max_radios_in_rbb then "\n" else "" endif 
             | i in 1..max_rbbs_in_sol, j in 1..max_radios_in_rbb] ++ ["]\n"] ++ 
       ["radio index in rbb = [\n"] ++ 
       [if j = 1 then "|" else "" endif ++ 
          if j < max_radios_in_sol then show(radio_index_in_rbb[i, j]) ++ ", " else show(radio_index_in_rbb[i, j]) ++ "\n" endif 
             | i in 1..max_rbbs_in_sol, j in 1..max_radios_in_sol] ++ ["]\n"] ++
       [if i = 1 then "carrier \(c), \(carrier_rbb_allocation[c]) = \n " ++ "tx/rx allocation = [" else "" endif ++
        show(carrier_tx_allocation[c, carrier_rbb_allocation[c], i ]) ++ 
        show(carrier_rx_allocation[c, carrier_rbb_allocation[c], i ]) ++
        if i < 8 then ", " else "]\n" endif | c in CarrierSet, i in 1..8] ++ ["\n"];
        
        
% functions
int: rbb_port_qty(rbb : r) =
  let { array[int] of int: hits = [ rbb_capability_nr_ports[i, 2] 
                                  | i in index_set_1of2(rbb_capability_nr_ports) where rbb_capability_nr_ports[i, 1] == r ]}
  in if card(index_set(hits)) == 1
     then min(hits)
     else abort("zero or more than one hits: rbb = \(r)")
     endif;