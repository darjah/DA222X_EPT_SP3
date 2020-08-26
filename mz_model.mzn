include "table.mzn";
include "alldifferent_except_0.mzn";
include "decreasing.mzn";

% project files
include "mz_data.dzn";
include "mz_testcase.dzn";

% tables
array[int, int] of int: ctc_ct_columns;
array[int, int] of int: node_ru_swrev;
array[int, int] of int: node_rbb_swrev;
array[int, int] of int: rbb_capability;
array[int, int] of int: rbb_capability_nr_ports;
array[int, int] of int: rbb_compatibility;
array[int, int] of int: rbb_ru_rat_swrev;
array[int, int] of int: rbb_ru_swrev; %!!!NA?!!!
array[int, int] of int: rbb_topology;
array[int, int] of int: ru_combinations;
array[int, int] of int: ru_combinations2;
array[int, int] of int: ru_fb;
array[int, int] of int: ru_data;
array[int, int] of int: ru_fb_bw_swrev;
array[int, int] of int: ru_fb_ctc_allowed;
array[int, int] of int: ru_fb_ctc_data;
array[int, int] of int: ru_fb_pm_pwr;
array[int, int] of int: ru_fbs_pms_pwr;
array[int, int] of int: ru_port_pattern;

% predefined parameters
int: max_nodes_in_sol = 8;
int: max_rbbs_in_sol = 8;
int: max_radios_in_sol = 6;
int: max_radios_in_rbb = 4;
int: nr_carriers_in_sol = card(CarrierSet);

% enums and sets with 0
enum swr;
enum node;
enum rbb;
enum ru; % ProductNumberHWRev
enum ru_type; % RUType
enum pwr_mode;
enum port_pattern;
enum port_name;

enum carrier_params = {FREQ_BAND, CARRIER_TYPE, NR_TX, NR_RX, BW, OUT_PWR, CARRIER_RAT};
enum freq_band;
enum carrier_type;
enum ctc;
int: BW_NONE = 0;
enum bandwidth;
enum carrier_rat;

array[int, int] of int: carriers;
set of int: CarrierSet = index_set_1of2(carriers);

set of int: node0 = 0..max(node);
set of int: rbb0 = 0..max(rbb);
set of int: ru0 = 0..max(ru);
set of int: ru_type0 = 0..max(ru_type);
set of int: port_pattern0 = 0..max(port_pattern);
set of int: pwr_mode0 = 0..max(pwr_mode);
set of int: ctc0 = 0..max(ctc);
set of int: freq_band0 = 0..max(freq_band);
set of int: bw0 = 0..max(bandwidth);

set of int: NodeSet = 1..max_nodes_in_sol;
set of int: RbbSet = 1..max_rbbs_in_sol;
set of int: RadioSet = 1..max_radios_in_sol;
set of int: RbbRadioSet = 1..max_radios_in_rbb;
set of int: PortSet = 1..8;
set of int: FreqSet = 1..max(freq_band);

% decision variables
var 0..max(swr): swrev;
var NodeSet: nr_selected_nodes;
var RbbSet: nr_selected_rbbs;
var RadioSet: nr_selected_radios;

/* nodes:
[ _, _, _, _, _, _, _, _,] */
array[NodeSet] of var node0: nodes;
/* rbbs:
[ _, _, _, _, _, _, _, _,] */
array[RbbSet] of var rbb0: rbbs;
/* radios:
[ _, _, _, _, _, _, _, _,] */
array[RadioSet] of var ru0: radios;
/* rbbs_in_nodes:
[ _, _, _, _, _, _, _, _,] */
array[RbbSet] of var 0..max_nodes_in_sol: rbbs_in_nodes;

/* radios_in_rbb:
[|1,  2,  0,  0
 |2,  0,  0,  0] */
array[RbbSet, RadioSet] of var 0..max_radios_in_sol: radios_in_rbb;

/* radio_index_in_rbb:
[|1,  2,  0,  0,  0,  0 
 |0,  1,  0,  0,  0,  0 ] */
array[RbbSet, RadioSet] of var 0..max_radios_in_rbb: radio_index_in_rbb;

/* carrier_rbb_allocation:
[ _, _, .., _,] */ 
array[CarrierSet] of var rbb0: carrier_rbb_allocation;

%carrier alloc to rbb rus
array[CarrierSet, RbbSet, RadioSet] of var 0..1: carrier_rbb_radio;

/* carrier_tx_allocation:
[|[| _, _, _, _, _, _, _, _,
   | _, _, _, _, _, _, _, _,
   ..
   | _, _, _, _, _, _, _, _]
 |[| _, _, _, _, _, _, _, _,
   | _, _, _, _, _, _, _, _,
   ..
   | _, _, _, _, _, _, _, _]
  .. 
 |[| _, _, _, _, _, _, _, _,
   | _, _, _, _, _, _, _, _,
   ..
   | _, _, _, _, _, _, _, _]]]*/
array[CarrierSet, RadioSet, PortSet] of var 0..1: carrier_tx_allocation;
array[CarrierSet, RadioSet, PortSet] of var 0..1: carrier_rx_allocation;

/* radio_ctc:
[ _, _, _, _, _, _] */
array[RadioSet] of var ctc0: radio_ctc;

%pwr_mode and port pattern / freq_band
array[RadioSet, FreqSet] of var pwr_mode0: radio_pwr_modes;
array[RadioSet, FreqSet] of var port_pattern0: radio_port_patterns;

/* radio_carrier_types:
[|_, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _
 |_, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _
 |_, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _
 |_, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _
 |_, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _
 |_, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _] */
array[RadioSet, 1..max(carrier_type)] of var 0..99: radio_carrier_types;
array[RadioSet, 1..max(freq_band)] of var 0..99: radio_freq_bands;

%array[RbbSet, 1..max(carrier_rat)] of var 0..99: rbb_carrier_rats;
/*---------------------------------------------------------------------------------------*/
constraint decreasing(radios);

% x with idx lesser than selected nr x must be greater than 0
constraint forall( i in NodeSet  ) ( if i <= nr_selected_nodes  then nodes[i] > 0         else nodes[i] = 0         endif );
constraint forall( i in RbbSet   ) ( if i <= nr_selected_rbbs   then rbbs[i] > 0          else rbbs[i] = 0          endif );
constraint forall( i in RadioSet ) ( if i <= nr_selected_radios then radios[i] > 0        else radios[i] = 0        endif );
constraint forall( i in RbbSet   ) ( if i <= nr_selected_rbbs   then rbbs_in_nodes[i] > 0 else rbbs_in_nodes[i] = 0 endif );

% propagate nr_selected_x
constraint nr_selected_nodes  = sum( i in NodeSet  ) ( bool2int( nodes[i] > 0 ) );
constraint nr_selected_rbbs   = sum( i in RbbSet   ) ( bool2int( rbbs[i] > 0 ) );
constraint nr_selected_radios = sum( i in RadioSet ) ( bool2int( radios[i] > 0 ) );

% each selected rbb must be connected to a node and that node must have an idx less than nr selected nodes
constraint forall( i in 1..nr_selected_rbbs ) 
                 ( rbbs_in_nodes[i] > 0 /\ rbbs_in_nodes[i] <= nr_selected_nodes );

% compatibility check: each rbb is connected to a compatible node
constraint forall( i in RbbSet ) 
                 ( let { var 0..max(swr): from_swrev } in
                 ( table( [ if rbbs_in_nodes[i] > 0 then nodes[rbbs_in_nodes[i]] else 0 endif, rbbs[i], from_swrev], node_rbb_swrev) /\
                   from_swrev <= swrev ) );
                   
% compatibility check: each radio in a rbb is compatible with the connected node
constraint forall( i in RbbSet, j in RbbRadioSet )
                 ( let { var 0..max(swr): from_swrev } in
                 ( table( [ rbbs_in_nodes[i], radios_in_rbb[i, j], from_swrev], node_ru_swrev) /\
                   from_swrev <= swrev ) );
                   
% one rbb cannot be connected to the same radio (idx) more than once
constraint forall( i in RbbSet ) 
                 ( alldifferent_except_0( [ radios_in_rbb[i, j] | j in RbbRadioSet ] ) );

% each rbb must be connected to exactly x radios
constraint forall( r in RbbSet ) 
                 ( table( [rbbs[r], sum( i in RbbRadioSet ) ( radios_in_rbb[r, i] > 0 ) ], rbb_topology ));

%-------                 
%% ha kvar dessa så att man använder alla r i radios i något av rbb:erna
% each radio in each rbb must be in the array of radios
constraint forall( r in RadioSet where radios[r] != 0 ) 
                 ( exists( i in RbbSet, j in RbbRadioSet ) ( radios_in_rbb[i,j] = r ));

% each radio in each rbb must be in the array of selected radios or 0
constraint forall( i in RbbSet, j in RbbRadioSet ) 
                 ( exists( r in RadioSet ) ( radios_in_rbb[i,j] = r \/ radios_in_rbb[i,j] = 0 )); 
%-------
% compatibility check: all radios in each rbb is according to valid combinations and specific order
/*constraint forall( i in RbbSet ) 
                 ( table([if radios_in_rbb[i,j] = 0 then 0 
                          else radios[radios_in_rbb[i,j]] endif | j in RbbRadioSet], ru_combinations));*/
constraint forall( i in RbbSet ) 
                 ( table([if radios_in_rbb[i,j] = 0 then 0 
                          else radios[radios_in_rbb[i,j]] endif | j in RbbRadioSet], ru_combinations2));
%inverse_set
constraint forall( i in RbbSet, j in RbbRadioSet ) 
                 ( radios_in_rbb[i, j] > 0 -> radio_index_in_rbb[i, radios_in_rbb[i, j]] = j );
                
constraint forall( i in RbbSet, j in RadioSet) 
                 ( radio_index_in_rbb[i, j] > 0 -> radios_in_rbb[i, radio_index_in_rbb[i, j]] = j);

/* "modelkiller"
svårt att prop med exists, lika så med -> TA BORT DESSA 
"exists = A OR B OR C... enda gången man kan prop exists det är om alla OR uttryck utom ett är false" 
a  b  a->b
0  0  1
0  1  1
1  0  0
1  1  1 */
% each pairwise combination of rbbs and radios are compatible
constraint forall( r1 in RbbSet, r2 in RbbSet where r1 != r2) 
                 ( exists( i in RadioSet ) ( ( radio_index_in_rbb[r1, i] > 0 /\ radio_index_in_rbb[r2, i] > 0 ) -> 
                   table( [rbbs[r1], radio_index_in_rbb[r1, i], rbbs[r2], radio_index_in_rbb[r2, i]], rbb_compatibility ) ) );

/*constraint forall( i in RadioSet ) 
                 ( if i <= nr_selected_radios then radio_ctc[i] > 0 else radio_ctc[i] = 0 endif );
constraint forall( i in RadioSet, f in FreqSet ) 
                 ( if i <= nr_selected_radios then radio_pwr_modes[i, f] > 0 else radio_pwr_modes[i, f] = 0 endif );*/

% each carrier must be allocated to (exactly) one rbb
constraint forall( c in CarrierSet ) ( carrier_rbb_allocation[c] > 0 );

% each rbb in the solution must have at least one carrier
constraint forall( r in RbbSet where rbbs[r] > 0 ) 
                 ( exists( c in CarrierSet ) ( carrier_rbb_allocation[c] = r ) );

% number of tx connections must be equal to NR_TX branches specified on the carrier
constraint forall( c in CarrierSet ) 
                 ( sum ( r in 1..nr_selected_radios, p in PortSet )( carrier_tx_allocation[c, r, p] ) = carriers[c, NR_TX] );

% number of rx connections must be equal to NR_RX branches specified on the carrier
constraint forall( c in CarrierSet ) 
                 ( sum ( r in 1..nr_selected_radios, p in PortSet )( carrier_rx_allocation[c, r, p] ) = carriers[c, NR_RX] );

% sum all allocated carrier branches' carrier types on each radio
constraint forall( r in RadioSet, ct in 1..max(carrier_type ) ) 
                 ( radio_carrier_types[r, ct] = 
                     sum( c in CarrierSet, p in PortSet where carriers[c, CARRIER_TYPE] = ct ) 
                        ( carrier_tx_allocation[c,r,p] + carrier_rx_allocation[c,r,p] ) );
% sum all allocated carrier branches' freq bands on each radio
constraint forall( r in RadioSet, f in 1..max(freq_band ) ) 
                 ( radio_freq_bands[r, f] = 
                     sum( c in CarrierSet, p in PortSet where carriers[c, FREQ_BAND] = f ) 
                        ( carrier_tx_allocation[c,r,p] ) );
                 
% sum all allocated carriers' carrier rats on each rbb
/*constraint forall( r in RbbSet, cr in 1..max(carrier_rat) )
                 ( rbb_carrier_rats[r, carrier_rat[cr]] = 
                   sum( c in CarrierSet where carriers[c, CARRIER_RAT] = cr) ( carrier_rbb_allocation[c] = r ) );*/

% count carriers allocated on rbb ru
constraint forall( c in CarrierSet, rbb in RbbSet, ru in RadioSet )
                 ( carrier_rbb_radio[c, rbb, ru] = 
                     bool2int( carrier_rbb_allocation[c] = rbb /\ 
                               sum( p in PortSet ) ( carrier_tx_allocation[c,ru,p] + carrier_rx_allocation[c,ru,p] ) > 0 ) );

% compatibility check: each radio in each rbb is compatible with that rbb !!!NA?!!!
constraint forall( i in RbbSet, j in RbbRadioSet) 
                 ( let { var int: from_swrev } in
                 ( radios_in_rbb[i,j] > 0 -> table([rbbs[i], radios[j], from_swrev], rbb_ru_swrev) /\
                  from_swrev <= swrev ) );
                  
% sw compatibility for carrier RATs allocated on rbb rus
constraint forall( c in CarrierSet, r in RadioSet where carrier_rbb_radio[c, carrier_rbb_allocation[c], r] = 1 ) 
                 ( let { var swr: from_swrev } in 
                 ( table( [ rbbs[carrier_rbb_allocation[c]], ru_data[radios[r], RU_TYPE], carriers[c, CARRIER_RAT], from_swrev ],               
                            rbb_ru_rat_swrev ) /\ 
                   from_swrev <= swrev ) );

% for each carrier, connected to an rbb, that port on that rbb must be tx/rx compatible 
% for allocation: carrier fb and tx/rx demands must be supported by radio specifications and in accordance to ru port pattern
% combination of carriers' carrier types must be supported by ru
constraint forall( c in CarrierSet, p in PortSet )
      ( let { var 0..1:              tx_capable,
              var 0..1:              rx_capable,
              var RbbRadioSet:       ru_idx,
              var 0..max(port_name): port_name,
              var 0..1:              ru_tx_capable,
              var 0..1:              ru_rx_capable, 
              var PortSet:           port_idx,
              var swr:               min_sw_rev1,
              var swr:               min_sw_rev2 } in
      ( table( [rbbs[carrier_rbb_allocation[c]], p, tx_capable, rx_capable, ru_idx, port_name], rbb_capability ) /\
        carrier_tx_allocation[c, radios_in_rbb[carrier_rbb_allocation[c], ru_idx], p] <= tx_capable /\
        carrier_rx_allocation[c, radios_in_rbb[carrier_rbb_allocation[c], ru_idx], p] <= rx_capable /\
        table( [radios[radios_in_rbb[carrier_rbb_allocation[c], ru_idx]], 
               carriers[c, FREQ_BAND], 
               radio_pwr_modes[radios_in_rbb[carrier_rbb_allocation[c], ru_idx], carriers[c, FREQ_BAND]], 
               radio_port_patterns[radios_in_rbb[carrier_rbb_allocation[c], ru_idx], carriers[c, FREQ_BAND]], 
               port_name, 
               port_idx,
               ru_tx_capable, 
               ru_rx_capable ], ru_port_pattern ) /\
        carrier_tx_allocation[c, radios_in_rbb[carrier_rbb_allocation[c], ru_idx], port_idx] <= ru_tx_capable /\
        carrier_rx_allocation[c, radios_in_rbb[carrier_rbb_allocation[c], ru_idx], port_idx] <= ru_rx_capable /\
        table( [radios[radios_in_rbb[carrier_rbb_allocation[c], ru_idx]], 
            carriers[c, FREQ_BAND], 
            carriers[c, BW], 
            min_sw_rev1], ru_fb_bw_swrev ) /\
            swrev >= min_sw_rev1 /\
            swrev >= min_sw_rev2 /\
        table( [radios[radios_in_rbb[carrier_rbb_allocation[c], ru_idx]], 
            carriers[c, FREQ_BAND], 
            radio_ctc[radios_in_rbb[carrier_rbb_allocation[c], ru_idx]], 
            min_sw_rev2], ru_fb_ctc_allowed) ) );

% allocated carrier types must within the available CTCs
set of int: tmp = {0, 99};
constraint forall( r in RadioSet ) (
    let { var tmp: ct_W_qty,
          var tmp: ct_NRHI_qty,
          var tmp: ct_NRTDD_qty,
          var tmp: ct_NRFDD_qty,
          var tmp: ct_NB_SA_qty,
          var tmp: ct_LTDD_qty,
          var tmp: ct_L_NB_IB_M1_qty,
          var tmp: ct_L_NB_IB_qty,
          var tmp: ct_L_NB_GB_M1_qty,
          var tmp: ct_L_NB_GB_qty,
          var tmp: ct_L_M1_qty,
          var tmp: ct_LLAA_qty,
          var tmp: ct_LFDD_qty,
          var tmp: ct_G_EC_qty,
          var tmp: ct_G_qty,
          var tmp: ct_C_qty,
          var tmp: ct_EFDD_qty } 
    in ( table( [ radio_ctc[r], 
                  ct_W_qty, 
                  ct_NRHI_qty,
                  ct_NRTDD_qty,
                  ct_NRFDD_qty,
                  ct_NB_SA_qty,
                  ct_LTDD_qty,
                  ct_L_NB_IB_M1_qty,
                  ct_L_NB_IB_qty,
                  ct_L_NB_GB_M1_qty,
                  ct_L_NB_GB_qty,
                  ct_L_M1_qty,
                  ct_LLAA_qty,
                  ct_LFDD_qty,
                  ct_G_EC_qty,
                  ct_G_qty,
                  ct_C_qty,
                  ct_EFDD_qty ] , ctc_ct_columns ) /\
                  radio_carrier_types[r,ct_W] <= ct_W_qty /\
                  radio_carrier_types[r,ct_NRHI] <= ct_NRHI_qty /\
                  radio_carrier_types[r,ct_NRTDD] <= ct_NRTDD_qty /\ 
                  radio_carrier_types[r,ct_NRFDD] <= ct_NRTDD_qty /\ 
                  radio_carrier_types[r,ct_NB_SA] <= ct_NB_SA_qty /\ 
                  radio_carrier_types[r,ct_LTDD] <= ct_LTDD_qty /\
                  radio_carrier_types[r,ct_L_NB_IB_M1] <= ct_L_NB_IB_M1_qty /\
                  radio_carrier_types[r,ct_L_NB_IB] <= ct_L_NB_IB_qty /\ 
                  radio_carrier_types[r,ct_L_NB_GB_M1] <= ct_L_NB_GB_M1_qty /\
                  radio_carrier_types[r,ct_L_NB_GB] <= ct_L_NB_GB_qty /\
                  radio_carrier_types[r,ct_L_M1] <= ct_L_M1_qty /\
                  radio_carrier_types[r,ct_LLAA] <= ct_LLAA_qty /\ 
                  radio_carrier_types[r,ct_LFDD] <= ct_LFDD_qty /\
                  radio_carrier_types[r,ct_G_EC] <= ct_G_EC_qty /\
                  radio_carrier_types[r,ct_G] <= ct_G_qty /\
                  radio_carrier_types[r,ct_C] <= ct_C_qty /\
                  radio_carrier_types[r,ct_EFDD] <= ct_EFDD_qty ) );

% check pwr restriction per radio port
constraint forall( r in RadioSet, f in FreqSet, p in PortSet)
                 ( let { var 0..120: port_pwr, 
                         var 0..400: radio_pwr} in 
                 ( table( [radios[r], f, radio_port_patterns[r, f], radio_pwr_modes[r, f], port_pwr, radio_pwr], ru_fb_pm_pwr ) /\
                   sum( c in CarrierSet where carriers[c, FREQ_BAND] = f ) 
                      ( carrier_tx_allocation[c, r, p] * (carriers[c, OUT_PWR]/carriers[c, NR_TX]) ) <= port_pwr ) );
                                      
% check pwr restriction on whole radio, for each combination of frequency bands (single to triple band)  
constraint forall( r in RadioSet, f in FreqSet )
                 ( let { var 0..120: port_pwr, 
                         var 0..400: radio_pwr} in 
                 ( table( [radios[r], f, radio_port_patterns[r, f], radio_pwr_modes[r, f], port_pwr, radio_pwr], ru_fb_pm_pwr ) /\
                   sum( p in PortSet, c in CarrierSet where carriers[c, FREQ_BAND] = f ) 
                      ( carrier_tx_allocation[c, r, p] * (carriers[c, OUT_PWR]/carriers[c, NR_TX]) ) <= radio_pwr ) );

enum RADIO_PARAMS = {RU_TYPE,FB1,FB2,FB3};
constraint forall( r in RadioSet where radios[r] != 0 /\ radio_freq_bands[r, ru_data[radios[r], FB1]] > 0 )
                 ( let { var 0..120: port_pwr,
                         var 0..400: radio_pwr } in 
                 ( table( [radios[r], ru_data[radios[r], FB1], 0, 0, 
                           radio_pwr_modes[r, ru_data[radios[r], FB1]], 0, 0, 
                           port_pwr, radio_pwr], ru_fbs_pms_pwr ) /\
                   sum( p in PortSet, c in CarrierSet where carriers[c, FREQ_BAND] = ru_data[radios[r], FB1] ) 
                      ( carrier_tx_allocation[c, r, p] * (carriers[c, OUT_PWR]/carriers[c, NR_TX]) ) <= radio_pwr ) );

constraint forall( r in RadioSet where radios[r] != 0 /\ radio_freq_bands[r, ru_data[radios[r], FB2]] > 0 )
                 ( let { var 0..120: port_pwr,
                         var 0..400: radio_pwr } in 
                 ( table( [radios[r], 0, ru_data[radios[r], FB2], 0, 
                           0, radio_pwr_modes[r, ru_data[radios[r], FB2]], 0, 
                           port_pwr, radio_pwr], ru_fbs_pms_pwr ) /\
                   sum( p in PortSet, c in CarrierSet where carriers[c, FREQ_BAND] = ru_data[radios[r], FB2] ) 
                      ( carrier_tx_allocation[c, r, p] * (carriers[c, OUT_PWR]/carriers[c, NR_TX]) ) <= radio_pwr ) );

constraint forall( r in RadioSet where radios[r] != 0 /\ 
                   radio_freq_bands[r, ru_data[radios[r], FB3]] > 0 )
                 ( let { var 0..120: port_pwr,
                         var 0..400: radio_pwr } in 
                 ( table( [radios[r], 0, 0, ru_data[radios[r], FB3],
                           0, 0, radio_pwr_modes[r, ru_data[radios[r], FB3]], 
                           port_pwr, radio_pwr], ru_fbs_pms_pwr ) /\
                   sum( p in PortSet, c in CarrierSet where carriers[c, FREQ_BAND] = ru_data[radios[r], FB3] ) 
                      ( carrier_tx_allocation[c, r, p] * (carriers[c, OUT_PWR]/carriers[c, NR_TX]) ) <= radio_pwr ) );  

constraint forall( r in RadioSet where radios[r] != 0 /\ 
                   radio_freq_bands[r, ru_data[radios[r], FB1]] > 0 /\ 
                   radio_freq_bands[r, ru_data[radios[r], FB2]] > 0 )
                 ( let { var 0..120: port_pwr,
                         var 0..400: radio_pwr } in 
                 ( table( [radios[r], ru_data[radios[r], FB1], ru_data[radios[r], FB2], 0,
                           radio_pwr_modes[r, ru_data[radios[r], FB1]], radio_pwr_modes[r, ru_data[radios[r], FB2]], 0, 
                           port_pwr, radio_pwr], ru_fbs_pms_pwr ) /\
                   sum( p in PortSet, c in CarrierSet where 
                        carriers[c, FREQ_BAND] = ru_data[radios[r], FB1] \/ 
                        carriers[c, FREQ_BAND] = ru_data[radios[r], FB2] ) 
                      ( carrier_tx_allocation[c, r, p] * (carriers[c, OUT_PWR]/carriers[c, NR_TX]) ) <= radio_pwr ) ); 
                    
constraint forall( r in RadioSet where radios[r] != 0 /\ 
                   radio_freq_bands[r, ru_data[radios[r], FB1]] > 0 /\ 
                   radio_freq_bands[r, ru_data[radios[r], FB3]] > 0 )
                 ( let { var 0..120: port_pwr,
                         var 0..400: radio_pwr } in 
                 ( table( [radios[r], ru_data[radios[r], FB1], 0, ru_data[radios[r], FB3],
                           radio_pwr_modes[r, ru_data[radios[r], FB1]], 0, radio_pwr_modes[r, ru_data[radios[r], FB3]], 
                           port_pwr, radio_pwr], ru_fbs_pms_pwr ) /\
                   sum( p in PortSet, c in CarrierSet where 
                        carriers[c, FREQ_BAND] = ru_data[radios[r], FB1] \/ 
                        carriers[c, FREQ_BAND] = ru_data[radios[r], FB3]) 
                      ( carrier_tx_allocation[c, r, p] * (carriers[c, OUT_PWR]/carriers[c, NR_TX]) ) <= radio_pwr ) );
                    
constraint forall( r in RadioSet where radios[r] != 0 /\ 
                   radio_freq_bands[r, ru_data[radios[r], FB2]] > 0 /\ 
                   radio_freq_bands[r, ru_data[radios[r], FB3]] > 0 )
                 ( let { var 0..120: port_pwr,
                         var 0..400: radio_pwr } in 
                 ( table( [radios[r], 0, ru_data[radios[r], FB2], ru_data[radios[r], FB3],
                           0, radio_pwr_modes[r, ru_data[radios[r], FB2]], radio_pwr_modes[r, ru_data[radios[r], FB3]], 
                           port_pwr, radio_pwr], ru_fbs_pms_pwr ) /\
                   sum( p in PortSet, c in CarrierSet where 
                        carriers[c, FREQ_BAND] = ru_data[radios[r], FB2] \/ 
                        carriers[c, FREQ_BAND] = ru_data[radios[r], FB3]) 
                      ( carrier_tx_allocation[c, r, p] * (carriers[c, OUT_PWR]/carriers[c, NR_TX]) ) <= radio_pwr ) );
               
constraint forall( r in RadioSet where radios[r] != 0 /\ 
                   radio_freq_bands[r, ru_data[radios[r], FB1]] > 0 /\ 
                   radio_freq_bands[r, ru_data[radios[r], FB2]] > 0 /\ 
                   radio_freq_bands[r, ru_data[radios[r], FB3]] > 0 )
                 ( let { var 0..120: port_pwr,
                         var 0..400: radio_pwr } in 
                 ( table( [radios[r], 
                           ru_data[radios[r], FB1], ru_data[radios[r], FB2], ru_data[radios[r], FB3],
                           radio_pwr_modes[r, ru_data[radios[r], FB1]], 
                           radio_pwr_modes[r, ru_data[radios[r], FB2]], 
                           radio_pwr_modes[r, ru_data[radios[r], FB3]], 
                           port_pwr, radio_pwr], ru_fbs_pms_pwr ) /\
                   sum( p in PortSet, c in CarrierSet where 
                        carriers[c, FREQ_BAND] = ru_data[radios[r], FB1] \/ 
                        carriers[c, FREQ_BAND] = ru_data[radios[r], FB2] \/ 
                        carriers[c, FREQ_BAND] = ru_data[radios[r], FB3] ) 
                      ( carrier_tx_allocation[c, r, p] * (carriers[c, OUT_PWR]/carriers[c, NR_TX]) ) <= radio_pwr ) );   
                    
array[RadioSet] of var int: radio_pwr;
constraint forall( r in RadioSet where radios[r] != 0 ) 
                 ( radio_pwr[r] = sum( c in CarrierSet, p in PortSet ) 
                                     ( carrier_tx_allocation[c, r, p] * (carriers[c, OUT_PWR]/carriers[c, NR_TX] ) ) );
/*---------------------------------------------------------------------------------------*/
% check pwr restriction on each port on a radio, for each combination of frequency bands (single to triple band)  
constraint forall( r in RadioSet, p in PortSet where radios[r] != 0 /\ 
                   radio_freq_bands[r, ru_data[radios[r], FB1]] > 0 )
                 ( let { var 0..120: port_pwr,
                         var 0..400: radio_pwr } in 
                 ( table( [radios[r], 
                           ru_data[radios[r], FB1], 0, 0, 
                           radio_pwr_modes[r, ru_data[radios[r], FB1]], 0, 0, 
                           port_pwr, radio_pwr], ru_fbs_pms_pwr ) /\
                   sum( c in CarrierSet where carriers[c, FREQ_BAND] = ru_data[radios[r], FB1] ) 
                      ( carrier_tx_allocation[c, r, p] * ( carriers[c, OUT_PWR] / carriers[c, NR_TX] ) ) <= port_pwr ) );

constraint forall( r in RadioSet, p in PortSet where radios[r] != 0 /\ 
                   radio_freq_bands[r, ru_data[radios[r], FB2]] > 0 )
                 ( let { var 0..120: port_pwr,
                         var 0..400: radio_pwr } in 
                 ( table( [radios[r], 
                           0, ru_data[radios[r], FB2], 0, 
                           0, radio_pwr_modes[r, ru_data[radios[r], FB2]], 0, 
                           port_pwr, radio_pwr], ru_fbs_pms_pwr ) /\
                   sum( c in CarrierSet where carriers[c, FREQ_BAND] = ru_data[radios[r], FB2] ) 
                      ( carrier_tx_allocation[c, r, p] * ( carriers[c, OUT_PWR] / carriers[c, NR_TX] ) ) <= port_pwr ) );

constraint forall( r in RadioSet, p in PortSet where radios[r] != 0 /\ 
                   radio_freq_bands[r, ru_data[radios[r], FB3]] > 0 )
                 ( let { var 0..120: port_pwr,
                         var 0..400: radio_pwr } in 
                 ( table( [radios[r], 
                           0, 0, ru_data[radios[r], FB3],
                           0, 0, radio_pwr_modes[r, ru_data[radios[r], FB3]], 
                           port_pwr, radio_pwr], ru_fbs_pms_pwr ) /\
                   sum( c in CarrierSet where carriers[c, FREQ_BAND] = ru_data[radios[r], FB3] ) 
                      ( carrier_tx_allocation[c, r, p] * ( carriers[c, OUT_PWR] / carriers[c, NR_TX] ) ) <= port_pwr ) );  

constraint forall( r in RadioSet, p in PortSet where radios[r] != 0 /\ 
                   radio_freq_bands[r, ru_data[radios[r], FB1]] > 0 /\ 
                   radio_freq_bands[r, ru_data[radios[r], FB2]] > 0 )
                 ( let { var 0..120: port_pwr,
                         var 0..400: radio_pwr } in 
                 ( table( [radios[r], ru_data[radios[r], FB1], ru_data[radios[r], FB2], 0,
                           radio_pwr_modes[r, ru_data[radios[r], FB1]], radio_pwr_modes[r, ru_data[radios[r], FB2]], 0, 
                           port_pwr, radio_pwr], ru_fbs_pms_pwr ) /\
                   sum( c in CarrierSet where 
                        carriers[c, FREQ_BAND] = ru_data[radios[r], FB1] \/ carriers[c, FREQ_BAND] = ru_data[radios[r], FB2]) 
                      ( carrier_tx_allocation[c, r, p] * ( carriers[c, OUT_PWR] / carriers[c, NR_TX] ) ) <= port_pwr ) ); 
                    
constraint forall( r in RadioSet, p in PortSet where radios[r] != 0 /\ 
                   radio_freq_bands[r, ru_data[radios[r], FB1]] > 0 /\ 
                   radio_freq_bands[r, ru_data[radios[r], FB3]] > 0 )
                 ( let { var 0..120: port_pwr,
                         var 0..400: radio_pwr } in 
                 ( table( [radios[r], ru_data[radios[r], FB1], 0, ru_data[radios[r], FB3],
                           radio_pwr_modes[r, ru_data[radios[r], FB1]], 
                           0, 
                           radio_pwr_modes[r, ru_data[radios[r], FB3]], 
                           port_pwr, radio_pwr], ru_fbs_pms_pwr ) /\
                   sum( c in CarrierSet where 
                        carriers[c, FREQ_BAND] = ru_data[radios[r], FB1] \/ 
                        carriers[c, FREQ_BAND] = ru_data[radios[r], FB3]) 
                      ( carrier_tx_allocation[c, r, p] * ( carriers[c, OUT_PWR] / carriers[c, NR_TX] ) ) <= port_pwr ) );
                    
constraint forall( r in RadioSet, p in PortSet where radios[r] != 0 /\ 
                   radio_freq_bands[r, ru_data[radios[r], FB2]] > 0 /\ 
                   radio_freq_bands[r, ru_data[radios[r], FB3]] > 0 )
                 ( let { var 0..120: port_pwr,
                         var 0..400: radio_pwr } in 
                 ( table( [radios[r], 0, ru_data[radios[r], FB2], ru_data[radios[r], FB3],
                           0, 
                           radio_pwr_modes[r, ru_data[radios[r], FB2]], 
                           radio_pwr_modes[r, ru_data[radios[r], FB3]], 
                           port_pwr, radio_pwr], ru_fbs_pms_pwr ) /\
                   sum( c in CarrierSet where 
                        carriers[c, FREQ_BAND] = ru_data[radios[r], FB2] \/ 
                        carriers[c, FREQ_BAND] = ru_data[radios[r], FB3]) 
                      ( carrier_tx_allocation[c, r, p] * ( carriers[c, OUT_PWR] / carriers[c, NR_TX] ) ) <= port_pwr ) );
               
constraint forall( r in RadioSet, p in PortSet where radios[r] != 0 /\ 
                   radio_freq_bands[r, ru_data[radios[r], FB1]] > 0 /\ 
                   radio_freq_bands[r, ru_data[radios[r], FB2]] > 0 /\ 
                   radio_freq_bands[r, ru_data[radios[r], FB3]] > 0 )
                 ( let { var 0..120: port_pwr,
                         var 0..400: radio_pwr } in 
                 ( table( [radios[r], 
                           ru_data[radios[r], FB1], ru_data[radios[r], FB2], ru_data[radios[r], FB3],
                           radio_pwr_modes[r, ru_data[radios[r], FB1]], 
                           radio_pwr_modes[r, ru_data[radios[r], FB2]], 
                           radio_pwr_modes[r, ru_data[radios[r], FB3]], 
                           port_pwr, radio_pwr], ru_fbs_pms_pwr ) /\
                   sum( c in CarrierSet where 
                        carriers[c, FREQ_BAND] = ru_data[radios[r], FB1] \/ 
                        carriers[c, FREQ_BAND] = ru_data[radios[r], FB2] \/ 
                        carriers[c, FREQ_BAND] = ru_data[radios[r], FB3] ) 
                      ( carrier_tx_allocation[c, r, p] * ( carriers[c, OUT_PWR] / carriers[c, NR_TX] ) ) <= port_pwr ) ); 
%---------------------------------------------------------------------------------------------------------------------------------------
solve satisfy;

output["swrev = \(to_enum(swr, swrev))\n",
       "nr_selected_nodes = \(nr_selected_nodes)\n",
       "nr_selected_radios = \(nr_selected_radios)\n",
       "nr_selected_rbbs = \(nr_selected_rbbs)\n",
       "nodes = ["] ++ 
       [if fix(nodes[i]) != 0 then show(to_enum(node, nodes[i])) ++ ", " else "" endif | i in NodeSet] ++ ["]\n"] ++
       ["rbbs in nodes = [" ] ++
       [if fix(rbbs_in_nodes[i]) != 0 then show(rbbs_in_nodes[i]) ++ ", " else "" endif | i in NodeSet] ++ ["]\n"] ++
       ["rbbs = ["] ++ 
       [if fix(rbbs[i]) != 0 then show(to_enum(rbb, rbbs[i])) ++ ", " else "" endif | i in RbbSet] ++ ["]\n"] ++
       ["radios = ["] ++ 
       [if fix(radios[i]) != 0 then show(to_enum(ru, radios[i])) ++ ", " else "" endif | i in RadioSet] ++ ["]\n"] ++
       ["radio ru types = ["] ++ 
       [if fix(radios[i]) != 0 then show(to_enum(ru_type, ru_data[radios[i], RU_TYPE])) ++ ", " else "" endif | i in RadioSet] ++ ["]\n"] ++
       ["radio port patterns = [\n"] ++
       [if j = 1 then "|" else "" endif ++
        if fix(radio_port_patterns[i,j]) != 0 then show(to_enum(port_pattern, radio_port_patterns[i, j])) ++ ", " else "0, " endif ++
        if j = max(FreqSet) then "\n" else "" endif ++ 
        if i = max(RadioSet) /\ j = max(FreqSet) then "]" else "" endif
       | i in RadioSet, j in FreqSet] ++ ["\n"] ++  
       ["radio pwr modes = [\n"] ++
       [if j = 1 then "|" else "" endif ++
        if fix(radio_pwr_modes[i, j]) != 0 then show(to_enum(pwr_mode, radio_pwr_modes[i,j])) ++ ", " else "0, " endif ++
        if j = max(FreqSet) then "\n" else "" endif ++ if i = max(RadioSet) /\ j = max(FreqSet) then "]" else "" endif
       | i in RadioSet, j in FreqSet] ++ ["\n"] ++ 
       ["radio CTC = ["] ++ 
       [if fix(radio_ctc[i]) != 0 then show(to_enum(ctc, radio_ctc[i])) ++ ", " else "" endif | i in RadioSet] ++ ["]\n"] ++
       ["radios in rbb = [\n"] ++ 
       [if j = 1 then "|" else "" endif ++ 
        if fix(radios_in_rbb[i,j]) != 0 then show(to_enum(ru, radios[radios_in_rbb[i,j]])) ++ ", " else "0, " endif ++ 
        if j = max_radios_in_rbb then "\n" else "" endif | i in RbbSet, j in RbbRadioSet] ++ ["]\n"] ++ 
       ["radio index in rbb = [\n"] ++ 
       [if j = 1 then "|" else "" endif ++ show(radio_index_in_rbb[i, j]) ++
        if j < max_radios_in_sol then ", " else "\n" endif | i in 1..max_rbbs_in_sol, j in 1..max_radios_in_sol] ++ ["]\n"] ++
       [if i = 1 then "c\(c), radio\(r) = \n " ++ "tx/rx allocation = [" else "" endif ++
        show(carrier_tx_allocation[c, r, i ]) ++ 
        show(carrier_rx_allocation[c, r, i ]) ++
        if i < 8 then ", " else "]\n" endif | c in CarrierSet, r in 1..fix(nr_selected_radios), i in 1..8] ++
       ["radio carrier types = [\n"] ++ 
       [if j = 1 then "|" else "" endif ++ show(radio_carrier_types[i, j]) ++
        if j < max(carrier_type) then  ", " else "\n" endif | i in RadioSet, j in 1..max(carrier_type)] ++ ["]\n"] ++
       ["carrier to rbb ru alloc \n"] ++
       [if rbb = 1 /\ ru = 1 then "c\(c) = " ++ "[" else "" endif ++
        if rbb = 1 then "\n|" else "" endif ++ show(carrier_rbb_radio[c, rbb, ru]) ++ 
        if ru <= card(RadioSet) then "," else "\n" endif ++ 
        if rbb = card(RbbSet) /\ ru = card(RadioSet) then "]\n" else "" endif | c in CarrierSet, ru in RadioSet, rbb in RbbSet]++ 
       [if fix(radios[r]) != 0 then "consumed pwr on radio \(r), " ++ 
        show(to_enum(ru, radios[r])) ++ ": " ++ 
        show(radio_pwr[r]) ++ "\n" else "" endif | r in RadioSet];

/* these two constraints are a suggestion of how to check the 
   number of allocated ul/dl carrier branches on a radio and its ports.
   TODO: when running -> result unsatisfiable. Investigate why, check data.
constraint forall( r in RadioSet, fb in FB1..FB3, ctc in ctc ) %radio
                 ( let { var 0..99: dlp, 
                         var 0..99: ulp, 
                         var 0..99: dlr, 
                         var 0..99: ulr } in
                  ( table( [radios[r], ru_data[radios[r], fb], ctc, dlp, ulp, dlr, ulr], ru_fb_ctc_data ) ) /\
                  ( dlr > 0 -> sum( c in CarrierSet where carriers[c, FREQ_BAND] = fb, p in PortSet ) 
                                  ( carrier_tx_allocation[c, r, p] ) < dlr ) /\
                  ( ulr > 0 -> sum( c in CarrierSet where carriers[c, FREQ_BAND] = fb, p in PortSet ) 
                                  ( carrier_rx_allocation[c, r, p] ) < ulr ) );
                                                     
constraint forall( r in RadioSet, p in PortSet, fb in FB1..FB3, ctc in ctc ) %port
                 ( let { var 0..99: dlp, 
                         var 0..99: ulp, 
                         var 0..99: dlr, 
                         var 0..99: ulr } in
                  ( table( [radios[r], ru_data[radios[r], fb], ctc, dlp, ulp, dlr, ulr], ru_fb_ctc_data ) ) /\
                  ( dlp > 0 -> sum( c in CarrierSet where carriers[c, FREQ_BAND] = fb ) 
                                  ( carrier_tx_allocation[c, r, p] ) < dlp ) /\
                  ( ulp > 0 -> sum( c in CarrierSet where carriers[c, FREQ_BAND] = fb ) 
                                  ( carrier_rx_allocation[c, r, p] ) < ulp ) );*/  