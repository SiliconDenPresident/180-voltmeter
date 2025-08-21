/////////////////////////////////////////
// Globals
/////////////////////////////////////////
var tbl_file = null; // required
var cfg_file = null; // optional
var files_list_length = 0;
var files_list_position = 0;
var top_url;
var full_config_file;
var config = {}; // root config item, filled in with containers below...

// EPSILON  is the difference between 1 and the smallest floating point number greater than 1
var EPSILON = 2.220446049250313e-16;  // ie has no Number.EPSILON
// full file collection
config.file_list         = [];  // simple list of file names for user to select from
config.file_contents_map = {}; // map of encoded file names (from list above) with raw data from file
// Name maps, keeping file names under their keys.
// The keys are generated from names by encode_name()
config.file_name_map     = {};
config.row_name_map      = {};
config.column_name_map   = {};

// selected files collection
config.active_file_list         = [];
//config.active_div_list          = []; // list of divs containing files currently displayed
config.active_scroll_table_list = []; // list of scrollable tables currently rendered (actual <table> elements)
config.active_fixed_table_list  = []; // list of fixed tables currently rendered (actual <table> elements)
config.active_json_list         = [];  // list of json content currently rendered

// temporary maps used for user input collection
// ONLY used to collect names during selection.  Cleared on popop, processed on Done key.
// Note that the keys here are the actual item name, NOT the encoded version.
config._active_files_map = {};
config._active_rows_map = {};
config._active_columns_map = {};
// full column collection
config.column_list = []; // names of all the columns in the reference table
config.columns_specified = false; // whether user overrode in config

config.active_columns_list = [];
config.row_list = [];
config.rows_specified = false; // whether user overrode in config
config.active_rows_list = [];
// variables are stored here, for use in coloring rules that eventually end up in config.format_map
config.variable_map = {}
config.number_vars=['light_pct','medium_pct','dark_pct','abs_threshold'];
// color rules are stored here.  They are almost immediately propagated into the format_map below.
config.rule_map = {}
// coloring rules are stored here (format.cfg, FORMAT|...)
config.format_map = {};

// reference table
config.reference_table = ''; // gets a real value first time table selection dlg pops up

var column_padding = 5; // extra space for column data to stop crowding
var table_controls_adjusted = false;
// Errors will set this to true, and we get a purposely dead page (no buttons will appear).
var error_reported = false;

// defined in html:
// data_directory


// Canvas -- used for td width calculations so we can explicitly control the table
//getTextWidth = {};
canvas = document.createElement("canvas");
var context = canvas.getContext("2d");
//context.font = '8 pt VeraSansMono';
//context.font = "8 px Lucida Sans Typewriter";
//context.font = "8pt sans-serif";
context.font = "8pt VeraSansMono";
// above is used in getTextWidth
// Display toggle.  Gets cycled with mouse right-click;
var display_toggle_states = ['PERCENTAGE','RAW','DELTA'];
var toggle_state = 0; // 0, 1, or 2, to index into display_toggle_states
var display_toggle_state = display_toggle_states[toggle_state];


///////////////////////////////////////////////////////////////////////////
// jquery hook, called very early
///////////////////////////////////////////////////////////////////////////
function init(){
    tbl_file = data_directory+'/tbl.cfg';    // required
    cfg_file = data_directory+'/format.cfg'; // optional
}


///////////////////////////////////////////////////////////////////////////
// javascript hook, gets called when all document pieces in place
///////////////////////////////////////////////////////////////////////////
function document_loaded(){
    sanity_checks();
    var loadedStyles = document.getElementsByTagName("link");
    top_url = loadedStyles[0].href;
    var lastSlashInFilepath = top_url.lastIndexOf('/');
    top_url = top_url.substring(0,lastSlashInFilepath);
    our_tbl_file = top_url + '/' + tbl_file;
    $("#lynx_stub").load(our_tbl_file, load_initial_table_config); // required
    our_cfg_file = top_url + '/' + cfg_file;
    $("#lynx_stub").load(our_cfg_file, load_initial_config);       // optional

     // Disable right-click context menu so right-click can be used to change the
     // metric display in non-reference tables with toggle_table_display_state()
    document.oncontextmenu = function() {return false;};
}


// called early, once
function sanity_checks(){
    if ( typeof data_directory == 'undefined' ){
        report_status("data_directory must be defined in the html file", 'ERROR');
    }
}


// right-click method hook
$("html").on("mousedown","body", function(e) {
    if( e.button == 2 ) {
        toggle_table_display_state();
    }
});


// User right-clicked, so we need to advance the table display to the next mode
function toggle_table_display_state(){
    toggle_state += 1;
    if (toggle_state == 3){toggle_state = 0;}
    display_toggle_state = display_toggle_states[toggle_state];
    set_display_state();
    recalc_tables();
}


// Tell user what display state we are in
function set_display_state(){
    txt = display_toggle_state.toLowerCase();
    console.log('state:'+txt)
    $("#toggle_area").text(txt);
}


// Handle OPTIONAL file: cfg_file, or our_cfg_file, which just has top_url prepended
// xhr.statusText can be OK, xhr.status can be 200, status only observed to be 'success'
function load_initial_config( data, status, xhr ){
    if ( status == 'success' ){
        if ( data.startsWith("<html>") ){
            console.log("Optional config file "+cfg_file+" not present, or not readable.");
        }else{
            process_config_contents( data );
        }
    }
}


// Handle REQUIRED file: tbl_file
// xhr.statusText can be OK, xhr.status can be 200, status only observed to be 'success'
function load_initial_table_config( data, status, xhr ){
    if ( status == 'success' ){
        if ( data.startsWith("<html>") ){
            report_status("table config file "+tbl_file+" not present, or not readable", 'ERROR');
            //$("#lynx_status").text("table config file "+tbl_file+" not present, or not readable");
        }else{
            process_table_config_contents( data );
        }
    }else{
        report_status("config file "+tbl_file+" not found, or not readable", 'ERROR');
        //$("#lynx_status").text("config file "+tbl_file+" not found, or not readable"); // different msg on purpose
    }
}


// We are here because we managed to read the (optional) config file in cfg_file or our_cfg_file.
function process_config_contents( cntnt ){
    contents = cntnt.split("\n");
    for (var i=0; i<contents.length; i++){
        var s = contents[i].trim();
        if (s.startsWith("#")){continue;} // commented
        if (s.length == 0){continue;} // blank line
        process_cfg_line(s);
    }
    // Now that all lines are read and processed, get named rules and put in the formats that call them.
    Object.keys(config.format_map).forEach(function(key) {
        entry = config.format_map[key];
        rule_name = entry.rule_name
        if (typeof rule_name != 'undefined' ){
            console.log('need to process '+key+' and replace its value with contents of '+entry.rule_name)
            new_contents = config.rule_map[rule_name]
            if (typeof new_contents == 'undefined'){
                report_status('No rule '+rule_name+' in the rule_map. It is referenced by '+key, 'ERROR');
                return;
            }else{
                // named rule  is there, so go populate referencing rule with referenced rule's settings
                populate_rule(new_contents, entry);
            }
        }
    });
}


// We are here because we managed to read the (required) config file in tbl_file
function process_table_config_contents( cntnt ){
    contents = cntnt.split("\n");
    for (var i=0; i<contents.length; i++){
        var s = contents[i].trim();
        if (s.startsWith("#")){continue;} // commented
        if (s.length == 0){continue;} // blank line
        process_file_line(s);
    }
    // The above has set file names into a list.  We need to get these names
    // and read the contents into the file map in config.
    files_list_length = config.file_list.length;
    fire_off();
}


function process_file_line( line ){
    config.file_list.push(line);
}


// process a pre-trimmed, useable line from the optional config file
function process_cfg_line( line ){
    if      (line.startsWith("HEADER")){process_header_line( line );}
    else if (line.startsWith("ROWS"))  {process_rows_line  ( line );}
    else if (line.startsWith("FORMAT")) {process_format_line ( line );}
    else if (line.startsWith("RULE")) {process_rule_line ( line );}
    else if (line.startsWith("VARIABLE")) {process_variable_line ( line );}
    else {console.warn('unrecognized line:'+line);}
}


// process a pre-trimmed, useable line from the config file containing a format (coloring rule)
// FORMAT|met. name|color|light pct|medium pct|dark pct|abs threshold|improves
function process_format_line( line ){
    format_line = line.split("|");
    format_line.splice(0, 1); // remove FORMAT tag from beginning
    // handle special case of one value provided, which would be a rule name to use
    if (format_line.length == 2){
        map = {}
        //metric_name = encode_name(format_line[0]);
        //rule_name = encode_name(format_line[1]);
        metric_name = format_line[0].trim();
        rule_name = format_line[1].trim();
        map['rule_name'] = rule_name;
        config.format_map[metric_name] = map;
        return;
    }
    if (format_line.length < 6){
        if (format_line.length == 0){
            report_status('Improper format for metric coloring rule. Needs 6 arguments total, none were provided.', 'ERROR');
        }else{
            report_status('Improper format for metric coloring rule '+format_line[0]+'. Needs 5 arguments after the name, '+(format_line.length-1)+' were provided.', 'ERROR');
        }
        return;
    }
    if (format_line.length > 6){
        report_status('Improper format for metric coloring rule '+format_line[0]+'. Needs 5 arguments after the name, '+(format_line.length-1)+' were provided.', 'ERROR');
    }
    metric_name = String(format_line.splice(0,1));
    metric_name = metric_name.trim();
    metric_map = validate_format('metric', metric_name, format_line);
    if (metric_map == null){ // we already told the user about the problem
        return;
    }
    //enc_name = encode_name(metric_name);
    config.format_map[metric_name] = metric_map;
}


// process a named coloring rule found in the file
// RULE|RULE_NAME|color|light pct|medium pct|dark pct|abs threshold|improves
function process_rule_line( line ){
    rule_line = line.split("|");
    rule_line.splice(0, 1); // remove RULE tag from beginning
    if (rule_line.length < 6){
        if (rule_line.length == 0){
            report_status('Improper format for named coloring rule. Needs 6 arguments total, none were provided.', 'ERROR');
        }else{
            report_status('Improper format for named coloring rule '+rule_line[0]+'. Needs 5 arguments after the name, '+(rule_line.length-1)+' were provided.', 'ERROR');
        }
        return;
    }
    if (rule_line.length > 7){
        report_status('Improper format for named coloring rule '+rule_line[0]+'. Needs 5 arguments after the name, '+(rule_line.length-1)+' were provided.', 'ERROR');
    }
    rule_name = rule_line.splice(0,1);
    //rule_name = encode_name(rule_name);
    rule_map = validate_format('rule', rule_name, rule_line);
    if (rule_map == null){
        return;
    }
    config.rule_map[rule_name] = rule_map;
}


// Variable lines hold default values to make format.cfg easier to create and maintain.
function process_variable_line ( line ){
    variable_line = line.split("|");
    variable_line.splice(0, 1); // remove VARIABLE tag from beginning
    if (variable_line.length != 2){
        console.log(line);
        report_status('Variable line has '+variable_line.length+' entries.  Variable lines must look like "VARIABLE|NAME|VALUE", but you have "'+line+'"', 'ERROR');
        return;
    }
    var_name = variable_line[0].trim();
    var_value = variable_line[1].trim();
    // make sure special vars are numeric (they all should be float, BTW)
    //if (config.number_vars.includes(var_name)){
      if (config.number_vars.indexOf(var_name) == -1){
        if (isNaN(var_value)){
            report_status('The variable '+var_name+' has to be numeric.  The value of '+var_value+' is not numeric.','ERROR');
            return;
        }
        // Make sure the variable setting passes name-specific tests
        if (var_name == 'abs_threshold'){
            if (var_value < 0){
                report_status('The variable '+var_name+' has to be a non-negative number.  The value of '+var_value+' is not a non-negative number.','ERROR');
                return;
            }
        }
        console.log('name='+var_name+', val='+var_value);
        config.variable_map[var_name]=parseFloat(var_value);
    }else{
        console.log('name='+var_name+', val='+var_value);
        config.variable_map[var_name]=var_value;
    }
}


// User entered a color format, either a named one or one for a metric.  It has 6 entries that we need to validate
function validate_format( tag, nm, arr ){
    ret_val = {};
    _light_pct = arr[0].trim();
    if (_light_pct.trim().length == 0){
        _light_pct = retrieve_var('light_pct');
    }
    if (isNaN(_light_pct) == true){
        report_status('light_pct for '+tag+' '+nm+' must be a number.  You provided '+_light_pct, 'ERROR');
        return null;
    }
    n_light_pct = Number(_light_pct);
    //if ((n_light_pct > 100) || (n_light_pct < 0)){
    //    report_status('light_pct for '+tag+' '+nm+' must be a number between 0 and 100.  You provided '+_light_pct, 'ERROR');
    //    return null;
    //}
    ret_val['light_pct'] = n_light_pct;
    _medium_pct = arr[1].trim();
    if (_medium_pct.trim().length == 0){
        _medium_pct = retrieve_var('medium_pct');
    }
    if (isNaN(_medium_pct) == true){
        report_status('medium_pct for '+tag+' '+nm+' must be a number.  You provided '+_medium_pct, 'ERROR');
        return null;
    }
    n_medium_pct = Number(_medium_pct);
    //if ((n_medium_pct > 100) || (n_medium_pct < 0)){
    //    report_status('medium_pct for '+tag+' '+nm+' must be a number between 0 and 100.  You provided '+_medium_pct, 'ERROR');
    //    return null;
    //}
    ret_val['medium_pct'] = n_medium_pct;
    _dark_pct = arr[2].trim();
    if (_dark_pct.trim().length == 0){
        _dark_pct = retrieve_var('dark_pct');
    }
    if (isNaN(_dark_pct) == true){
        report_status('dark_pct for '+tag+' '+nm+' must be a number.  You provided '+_dark_pct, 'ERROR');
        return null;
    }
    n_dark_pct = Number(_dark_pct);
    //if ((n_dark_pct > 100) || (n_dark_pct < 0)){
    //    report_status('dark_pct for '+tag+' '+nm+' must be a number between 0 and 100.  You provided '+_dark_pct, 'ERROR');
    //    return null;
    //}
    ret_val['dark_pct'] = n_dark_pct;
    _abs_threshold = arr[3].trim();
    if (_abs_threshold.trim().length == 0){
        _abs_threshold = retrieve_var('abs_threshold');
    }
    if (isNaN(_abs_threshold) == true){
        report_status('abs_threshold for '+tag+' '+nm+' must be a non-negative number.  You provided '+_abs_threshold, 'ERROR');
        return null;
    }
    if (_abs_threshold < 0){
        report_status('abs_threshold for '+tag+' '+nm+' must be a non-negative number.  You provided '+_abs_threshold, 'ERROR');
        return null;
    }
    n_abs_threshold = Number(_abs_threshold);
    ret_val['abs_threshold'] = n_abs_threshold;
    _improves = arr[4].toLowerCase().trim();
    if ((_improves != 'smaller') && (_improves != 'larger')) {
        report_status('Improves in format for '+tag+' '+nm+' needs to be smaller or larger, not '+arr[4]+'.', 'ERROR');
        return null;
    }
    ret_val['improves'] = _improves;
    return ret_val;
}


// Get the named variable from config.variable_map
function retrieve_var ( name ){
    if (name in config.variable_map){
        return config.variable_map[name];
    }
    return '';
}


// Kept near validate_format since they both deal with messy details of coloring rules.
// User specified a coloring rule that calls on a named coloring rule.  This will copy the
// actual contents of the named rule into the (empty) coloring rule that references it.
// At this point the named rule is guaranteed to be syntactically correct, and the empty_rule just has a name
function populate_rule ( named_rule, empty_rule ){
    empty_rule['abs_threshold'] = named_rule['abs_threshold'];
    empty_rule['color']         = named_rule['color'];
    empty_rule['dark_pct']      = named_rule['dark_pct'];
    empty_rule['improves']      = named_rule['improves'];
    empty_rule['light_pct']     = named_rule['light_pct'];
    empty_rule['medium_pct']    = named_rule['medium_pct'];
}


// Process config_file line starting with HEADER.
// (that is the line saying what columns to display)
function process_header_line( line ){
    config.columns_specified = true;
    var cols = line.split("|")
    cols.splice(0, 1); // remove HEADER tag from beginning
    config.active_columns_list.push(" ");
    for (var i=0; i<cols.length; i++){
        var col_name = cols[i];
        config.active_columns_list.push(col_name);
    }
}


// Process config_file line starting with ROWS.
// (that is the line saying what rows to display)
function process_rows_line( line ){
    config.rows_specified = true;
    var rows = line.split("|")
    rows.splice(0, 1); // remove ROWS tag from beginning
    config.active_rows_list.push(" ");
    for (var i=0; i<rows.length; i++){
        var row_name = rows[i];
        config.active_rows_list.push(row_name);
    }
}


// process config_file line starting with FILES
// these need directory, in data_directory in html
// top_url is used during file read
// DEFUNCT
function process_files_line( line ){
    var files = line.split("|")
    files.splice(0, 1); // remove FILES tag from beginning
    for (var i=0; i<files.length; i++){
        config.file_list.push(files[i]);
    }
}


// This function is called once after the config file is read in,
// at the end of process_config_contents.  Purpose is to start a call chain that will
// read in all the files, but since that uses jquery load, which works asynchronously,
// we need to have the end of that asynchronous function, load_this_file, increment
// a variable and come back through fire_off.  That way we read all the files in and manage
// to do it in sequence.
function fire_off(){
    this_file = top_url + '/' + data_directory + '/' + config.file_list[files_list_position];
     $("#lynx_stub").load(this_file, load_this_file);
}


function load_this_file( data, status, xhr ){
    if (config.file_list.length == 0){
        report_status("There are no files listed in the config file at "+data_directory+'/'+config_file, 'ERROR')
        return;
    }
    var file_name = config.file_list[files_list_position];
    if (typeof file_name == 'undefined'){
        return;
    }
    var encoded_fl_name = encode_name(file_name);
    clean_data = clean(data);
    config.file_contents_map[encoded_fl_name] = clean_data;
    config.file_name_map[encoded_fl_name] = file_name;
    files_list_position++;
    if (files_list_position + 1 > files_list_length){
        console.log('LOADING DONE, painting');
        construct_top_controls();
        setup_for_initial_render();
        paint_page( true );
    }else{
        fire_off();
    }
}


// Kill any blank lines found in the file.
function clean( blob ){
    var cleaned = '';
    var lines = blob.split("\n");
    for (var i=0; i<lines.length; i++){
        var line = lines[i].trim();
        if (line.length > 0){
            cleaned += lines[i]+"\n";
        }
    }
    // this loop leaves an extra \n on the end, so we will nip it here
    cleaned = cleaned.slice(0, -1);
    return cleaned;
}


// User clicked a Done button on a popup, identified by location
function user_choices_complete( location ){
    if (location == 'tables'){curate_tables();}
    if (location == 'rows'){config.rows_specified = true; curate_rows();}
    if (location == 'cols'){config.columns_specified = true; curate_columns();}
    paint_page( false );
}


// User edieted their tables selection and clicked the 'Done' button, so get the settings from the popup table.
function curate_tables(){
    tbl = $('#tables_table');
    ordered_contents_list = iterate_popup_table(tbl);
    console.log('curating table selection');
    // first, capture the choice for reference table (curated radio button group, so exactly one will be chosen)
    rf  = $("input:radio[name='tables_ref_group']:checked").val();
    console.log('ref table:'+rf)
    if (config.reference_table != rf){
        console.log('>>>>>>>>>reference table has changed.')
        config.reference_table = rf;
        // config.reference_json = jsonify_contents( rf );
        reset_col_and_row_lists(rf);
    }
    config.reference_table = rf;
    config.active_file_list = [];
    for (var i=0; i<ordered_contents_list.length; i++){
        table_name = ordered_contents_list[i];
        //encoded_table_name = encode_name(table_name);
        if (table_name in config._active_files_map){
            console.log(table_name + ' was chosen');
            config.active_file_list.push(table_name);
        }
    }
    if (config.active_file_list.length == 0){
        config.active_file_list.push(config.reference_table);
    }
    // before we leave, take this ordered list we got and reorder the main file list
    config.file_list = ordered_contents_list.slice();
}


// User edited their rows selection and clicked the 'Done' button, so get the settings from the popup table.
function curate_rows(){
    tbl = $('#rows_table');
    ordered_contents_list = iterate_popup_table(tbl);
    console.log('curating row selection');
    // no references in this table
    config.active_rows_list = [];
    config.active_rows_list.push(" ");
    for (var i=0; i<ordered_contents_list.length; i++){
        this_one = ordered_contents_list[i];
        //encoded_name = encode_name(this_one)
        if (this_one in config._active_rows_map){
            config.active_rows_list.push(this_one);
        }
    }
    // before we leave, take this ordered list we got and reorder the main row list
    config.row_list = ordered_contents_list.slice();
    config.row_list.unshift(" ");
}


// User edited their columns selection and clicked the 'Done' button, so get the settings from the popup table.
function curate_columns(){
    tbl = $('#columns_table');
    ordered_contents_list = iterate_popup_table(tbl);
    console.log('curating row selection');
    config.active_columns_list = [];
    config.active_columns_list.push(" ");
    for (var i=0; i<ordered_contents_list.length; i++){
        name = ordered_contents_list[i];
        //encoded_name = encode_name(name);
        if (name in config._active_columns_map){
            config.active_columns_list.push(name);
        }
    }
    // before we leave, take this ordered list we got and reorder the main column list
    config.column_list = ordered_contents_list.slice();
    config.column_list.unshift(" ");
}


// The user may have used drag and drop to reorder the table,
// so we iterate it here and return the pertinent names in the new order.
function iterate_popup_table(table){
    var items = [];
    table.find('tr').each(function(rowIndex, r){
        $(this).find('td').each(function (colIndex, c){
            if (colIndex == 1){
                items.push(c.textContent);
            }
        });
    });
    console.log('items list has '+items.length+' things in it')
    return items;
}

// Gets called right before first call to paint_page.
// Purpose in life is to select files to display on initial render
function setup_for_initial_render(){
    if (config.file_list.length > 0){
        // Need to set row and column lists for first file.
        reset_col_and_row_lists(config.file_list[0]);
        config.reference_table = config.file_list[0];
        config.active_file_list.push(config.file_list[0]);
        lst_len = config.file_list.length;
        if (lst_len > 1){
            // We have at least two tables to show
            config.active_file_list.push(config.file_list[lst_len-1]);
        }
    }else{
        console.warn('No files found in data dir.  Nothing to render.')
    }
}


// wait        hand
// progress    nothing
// not-allowed nothing
function setWaitCursor(){
  console.log('WAIT CURSOR...');
  //document.body.style.cursor = "wait";
  //$('#loadingModal').show();
}
// turn cursor back to normal
function unsetWaitCursor(){
  console.log('NORMAL CURSOR')
  //document.body.style.cursor = "default";
  //$('#loadingModal').hide();
}

// all files are loaded, buttons rendered with construct_top_controls, so time to paint the page
function paint_page( first_load ){
    var anchor = $("#table_div");
    anchor.empty(); // clears off old versions of tables before iterating
    config.active_fixed_table_list = [];
    config.active_scroll_table_list = [];
    config.active_json_list = [];
    // Do not bother displaying toggle state if no files chosen.
    if (config.active_file_list.length > 0){
        set_display_state();
    }

    setWaitCursor();

    for (var i=0; i<config.active_file_list.length; i++){
        var table_name = config.active_file_list[i];
        // we cannot use table_name directly as part of an id, because the '.' in the name confuses jquery
        var encoded_table_name = encode_name(table_name);
        var reference = false;
        json = jsonify_contents(table_name)
        if (table_name == config.reference_table){
            reference = true;
            config.reference_json = json;
        }
        config.active_json_list.push(json);
        var local_table_div = $('<div class="table_holder" id="table_'+i+'"></div>');
        //config.active_div_list.push(local_table_div);
        anchor.append( local_table_div );
        // FYI, json and config.reference_json are the same if reference == true
        render_tables( table_name, encoded_table_name, local_table_div, json, reference, config.reference_json );
    }
    align_columns();
    // Tying all table scroll bars together...
    $('.scroll_table_div').scroll(function(){
        $('.scroll_table_div').scrollLeft($(this).scrollLeft());
    })

    unsetWaitCursor();
}


// PARMS:
// actual_name, encoded_name: file name and encoded version of same
// div: The table_div that gets appended to (the local div attached to the main table div in the html).
// json: the table contents to be rendered
// reference: whether or not we are rendering the reference table
// reference_json: the json of the reference table
// ACTION:
// Builds and puts divs and their tables into div parm.
// Puts tables in the two active_table_lists in config
// RETURN:
// Nothing
function render_tables( actual_name, encoded_name, div, json, reference, reference_json ){
    var fixed_table_append_val = '&nbsp;'; // puts a space on the right end of the cell text
    var encoded_table_id = 'table_'+encoded_name;
    // make the fiddly bits that go above the table (+ and the label)
    // This next div is here just to hold the table ids, making it easier to hide and display,
    // since this lets us just pass one id to construct_table_controls.
    var extra_div_id = encoded_table_id+'_div';
    var extra_div = $('<div class="extra_div" id="'+extra_div_id+'"/>');
    table_controls = construct_table_controls( extra_div_id, actual_name ); // was encoded_table_id
    div.append(table_controls);
    div.append(extra_div);
    //var table = $('<table class="comp_table" id="'+encoded_table_id+'"/>');
    var fixed_table_div  = $('<div class="fixed_table_div"/>');
    var scroll_table_div = $('<div class="scroll_table_div"/>');
    extra_div.append(fixed_table_div);  // was appended to div
    extra_div.append(scroll_table_div); // was appended to div

    //
    // First, build the fixed table on the left, which has the one leftmost column
    //
    var fixed_table = $('<table class=" fixed_table comp_table" id="fixed_table_'+encoded_table_id+'"/>');
    fixed_table_div.append(fixed_table);
    config.active_fixed_table_list.push(fixed_table);
    for (var row=0; row<config.active_rows_list.length; row++){
        var row_name = config.active_rows_list[row];
        var encoded_row_name = encode_name(row_name);
        var tr = null;
        if (row == 0){
            tr = $('<tr/>');
        }else{
            tr = $('<tr class="comp_table_row '+encoded_row_name+'" onmouseover="into_row(\''+encoded_row_name+'\');" onmouseout="outof_row(\''+encoded_row_name+'\')"/>');
        }
        fixed_table.append( tr );
        var hdr_cell_class='hdr_'+encoded_row_name;
        //for (var col=0; col<config.active_columns_list.length; col++){
        // just the one col here in the fixed table
        var col_name = config.active_columns_list[0];
        var encoded_col_name = encode_name(col_name);
        var cell_class = encoded_row_name+'_'+encoded_col_name;
        var cell = find_cell(json, row_name, col_name);
        title = '';
        if (cell.orphan == true){
            title = 'No row named '+row_name;
        }
        if (row == 0){
            tbl_cell = $('<th title="table: '+actual_name+'" class="'+hdr_cell_class+' header_colors row_header fixed_table_top_row" />');
        }else{
            tbl_cell = $('<td title="'+title+'" class="'+hdr_cell_class+' header_colors row_header fixed_table_row" />');
        }
        if (reference == true){
            // console.log('ref cell display data:['+cell.display_data+']');
            if ( row == 0 ){
                tbl_cell.html('REF');
            }else{
                tbl_cell.html(cell.display_data+fixed_table_append_val);
            }
        }else{
            // console.log('REG cell display data:['+cell.display_data+']');
            disp = calculate_display_value(row, row_name, 0, col_name, cell, reference_json);
            tbl_cell.html(disp+fixed_table_append_val);
        }
        // all coloring handled by coloring_class
        //tbl_cell.addClass(cell.coloring_class); // no coloring rules in this table, and header_colors applied already
        tr.append( tbl_cell );
        //} // just the one col here in the fixed table
    } // all rows in fixed table done now

    //
    // now build the scroll table on the right, which has columns 1 to the end
    //
    var scroll_table = $('<table class=" scroll_table comp_table" id="scroll_table_'+encoded_table_id+'"/>');
    scroll_table_div.append(scroll_table);
    config.active_scroll_table_list.push(scroll_table);
    for (var row=0; row<config.active_rows_list.length; row++){
        var row_name = config.active_rows_list[row];
        var encoded_row_name = encode_name(row_name);
        var tr = null;
        if (row == 0){
            tr = $('<tr/>');
        }else{
            tr = $('<tr class="comp_table_row '+encoded_row_name+'" onmouseover="into_row(\''+encoded_row_name+'\');" onmouseout="outof_row(\''+encoded_row_name+'\')"/>');
        }
        scroll_table.append( tr );
        //var hdr_cell_class='hdr_'+encoded_row_name;
        // starting col at 1 because col 0 is already in the fixed table we just drew
        for (var col=1; col<config.active_columns_list.length; col++){
            var col_name = config.active_columns_list[col];
            var encoded_col_name = encode_name(col_name);
            var cell_class = encoded_row_name+'_'+encoded_col_name;
            var cell = find_cell(json, row_name, col_name);
            if (row == 0){
                title = generate_column_title( cell, col_name );
                tbl_cell = $('<th title="'+title+'" class="row_header header_colors '+cell_class+'"/>');
            }else{
                // regular_colors or coloring rule results added at end.  Was wrong aws hdr_cell_class
                tbl_cell = $('<td class="'+cell_class+'" onmouseover="into_cell(\''+cell_class+'\');" onmouseout="outof_cell(\''+cell_class+'\')"/>');
            }
            tr.append(tbl_cell);
            if (reference == true){
                tbl_cell.html(cell.display_data);
            }else{
                disp = calculate_display_value(row, row_name, col, col_name, cell, reference_json);
                tbl_cell.html(disp);
                tbl_cell.addClass(cell.coloring_class);
            }
        } // thats it for columns
    }// all rows in scroll table done now
}


// Calculate display value from data in cell based on same location in reference_json.
// Then, return the proper one for display
function calculate_display_value(row, row_name, col, col_name, cell, reference_json){
    if (row == 0){return cell.display_data;}
    if (col == 0){return cell.display_data;}
    ref_cell = find_cell(reference_json, row_name, col_name);
    data = cell.data;
    ref_data = ref_cell.data;
    //return calculate(ref_data, data);
    calculate_all_display_values(cell, ref_cell);
    return return_display_value(cell);
}


// Calculates display values for the two non-RAW modes and stores them in cell.
function calculate_all_display_values( cell, reference_cell ){
    data = cell.data;
    ref_data = reference_cell.data;
    if ((data.trim().length == 0) || (ref_data.trim().length == 0)){
        cell.pct_data = cell.display_data;   // was just ''
        cell.delta_data = cell.display_data; // was just ''
        return;
    }
    n = Number(data);
    n_ref = Number(ref_data);
    if ((isNaN(n)) || (isNaN(n_ref))){
        cell.pct_data = cell.display_data;   // was cell.data
        cell.delta_data = cell.display_data; // was cell.data
        return;
    }
    // we know we have two numbers to work with now
    //cell.pct_data = percentage(n_ref, n);
    //cell.delta_data = delta(n_ref, n);
    percent_and_delta(cell, n_ref, n);
    apply_coloring_rules(cell, n, n_ref);
    return;
}


// Set the appropriate css class on the cell (used as background color).
function apply_coloring_rules(cell, n, n_ref){
    rule_name = cell.col_name;
    entry = config.format_map[rule_name];
    if (typeof entry == 'undefined'){return;}
    // Still here?  Coloring rule found.
    if (entry.color == 'none'){return;}
    abs_delta = Math.abs(cell.delta_data);
    // Even though 0 change is less than delta, do not gray out.
    if (abs_delta == 0){return;}
    if (abs_delta <= entry.abs_threshold){
        cell.coloring_class = 'below_threshold';
        return;
    }
    comparable = cell.comparable;
    if (entry.improves == 'larger'){
        if (comparable > 0){ // values rose compared to reference table, which is good
            if (comparable >= entry.dark_pct)  {cell.coloring_class = 'dg'; return;}
            if (comparable >= entry.medium_pct){cell.coloring_class = 'mg'; return;}
            if (comparable >= entry.light_pct) {cell.coloring_class = 'lg'; return;}

        }else{ // values fell compared to reference table, which is bad
            comparable = Math.abs(comparable);
            if (comparable >= entry.dark_pct)  {cell.coloring_class = 'dr'; return;}
            if (comparable >= entry.medium_pct){cell.coloring_class = 'mr'; return;}
            if (comparable >= entry.light_pct) {cell.coloring_class = 'lr'; return;}
        }
    }else if (entry.improves == 'smaller'){
        if (comparable > 0){ // values rose compared to reference table, which is bad
            if (comparable >= entry.dark_pct)  {cell.coloring_class='dr';return;}
            if (comparable >= entry.medium_pct){cell.coloring_class='mr';return;}
            if (comparable >= entry.light_pct) {cell.coloring_class='lr';return;}
        }else{ // values fell compared to reference table, which is good
            comparable = Math.abs(comparable);
            if (comparable >= entry.dark_pct)  {cell.coloring_class = 'dg'; return;}
            if (comparable >= entry.medium_pct){cell.coloring_class = 'mg'; return;}
            if (comparable >= entry.light_pct) {cell.coloring_class = 'lg'; return;}
        }
    }
}


function generate_column_title(cell, col_name ){
    rule_name = cell.col_name;
    entry = config.format_map[rule_name];
    if (typeof entry == 'undefined'){return 'No column named '+col_name ;}
    improves = entry.improves;
    return improves+' is better';
}


// Return cell's value for display depending on toggle setting.
function return_display_value(cell){
    if (display_toggle_state == 'PERCENTAGE'){return cell.pct_data;}
    if (display_toggle_state == 'DELTA'){return cell.delta_data;}
    return cell.display_data; // was just return cell.data
}


// Note that this function, and delta below it, might be faster with
// Math.round(num * multiplier) / multiplier
// DEFUNCT
function percentage(n_ref, n){
    v = n - n_ref;
    pct = v / Math.abs(n_ref);
    //pctage = pct * 100.0;
    pctage = Math.round( pct * 10000 + Number.EPSILON ) / 100; // 54.63
    return pctage+'%';
}


// DEFUNCT
function delta(n_ref, n){
    v = n - n_ref;
    prepend = '';
    if (v > 0.0){prepend = '+';}
    delta = Math.round( v * 100000 + Number.EPSILON ) / 100000;
    return prepend+delta;
}


// combination of percentage() and delta()
function percent_and_delta(cell, n_ref, n){
    //col_name 'HTNS' has NaN and -infinity results to handle
    v = n - n_ref;
    prepend = '';
    if (v > 0.0){prepend = '+';}
    //delta = Math.round( v * 100000 + Number.EPSILON ) / 100000;
    delta = Math.round( v * 100000 + EPSILON ) / 100000;
    cell.delta_data = prepend+delta.toString();
    pct = v / Math.abs(n_ref);
    if ((isNaN(pct)) || (! isFinite(pct))){
      cell.pct_data = n_ref+'%';
      cell.comparable = n_ref;
    }else{
      // pctage = pct * 100.0;
      //pctage = Math.round( pct * 10000 + Number.EPSILON ) / 100; // results like 54.63 from .5463
      pctage = Math.round( pct * 10000 + EPSILON ) / 100; // results like 54.63 from .5463
      cell.pct_data = pctage.toString()+'%';
      // Comparable is used in coloring rules, and we use the raw percent.
      cell.comparable = pctage;
    }
}


// We caught the user's right-click, reset global var, now we apply it
function recalc_tables(){
    for (i=0; i<config.active_scroll_table_list.length; i++){
        tbl = config.active_scroll_table_list[i];
        tbl_name = config.active_file_list[i];
        if (tbl_name == config.reference_table){
            continue; // leave display of reference table alone
        }
        json = config.active_json_list[i];
        // starting at row 1 because row 0 is header row
        for (j=1; j<config.active_rows_list.length; j++){
            row_name = config.active_rows_list[j];
            encoded_row_name = encode_name(row_name);
            // starting at col 1 because col 0 is header column
            for (k=1; k<config.active_columns_list.length; k++){
                column_name = config.active_columns_list[k];
                encoded_column_name = encode_name(column_name);
                //console.log('row '+row_name+', col '+column_name);
                ref_cell = find_cell(config.reference_json, row_name, column_name);
                cell     = find_cell(json,  row_name, column_name);
                //new_val = calculate(ref_cell.data, cell.data);
                new_val = return_display_value(cell);
                cell_class = encoded_row_name+'_'+encoded_column_name;
                tee_dee = tbl.find('.'+cell_class);
                tee_dee.html(new_val);
            }
        }
    }
    align_columns();
}


// user rolled the mouse into a table row
function into_row( rname ){
    var hdr_cell_class='hdr_'+rname;
    $("."+rname).addClass("highlighted_row");
    $("."+hdr_cell_class).addClass("highlighted_row_header");
}


// user rolled the mouse out of the table row they were in
function outof_row( rname ){
    var hdr_cell_class='hdr_'+rname;
    $("."+rname).removeClass("highlighted_row");
    $("."+hdr_cell_class).removeClass("highlighted_row_header");
}


// user rolled the mouse into a cell
function into_cell( nm ){
    $("."+nm).addClass("highlighted_cell");
}


// user rolled the mouse out of the cell they were in
function outof_cell( nm ){
    $("."+nm).removeClass("highlighted_cell");
}


// Makes the control buttons at the very top.
function construct_top_controls(){
    if (error_reported == true){
        console.error('Processing halted because of error.  See main display.')
        return;
    }
    var the_div = $('#control_anchor');
    tables_btn = $('<button id="tables_btn" class="top_button" onclick="choose_tables();">Choose Tables</button>');
    the_div.append(tables_btn);
    rows_btn = $('<button id="rows_btn" class="top_button" onclick="choose_rows();">Choose Rows</button>');
    the_div.append(rows_btn);
    cols_btn = $('<button id="cols_btn" class="top_button" onclick="choose_cols();">Choose Columns</button>');
    the_div.append(cols_btn);
    help_btn = $('<button id="help_btn" class="top_button" onclick="choose_help();">Help</button>');
    the_div.append(help_btn);
    toggle_state_area = $('<div id="toggle_area" class="state_area"></div>');
    the_div.append(toggle_state_area);

}


// user wants a popup to choose tables from
function choose_tables(){
    fill_table_area();
    $('#pickTablesModal').show();
    //$('#tables_table').tableDnD();
    $('#tables_table').tableDnD({ onDragClass: "myDragClass" });
}


// fill in the 'Choose Tables' popup for the user
function fill_table_area(){
    // Put something useful in the help icon
    help_icon = $('#table_help_icon');
    help_icon.attr('title','Checkbox selects table,\n radio in Ref column selects reference table,\n reorder table display by dragging/dropping rows.');
    config._active_files_map = {};
    var table = $('#tables_table');
    table.empty();

    // sanity check
    if (config.file_list.length == 0){
        report_status("There are no files listed in the config file at "+data_directory+'/'+config_file, 'ERROR');
        return;
    }
    //
    // make the header row
    //
    header_row = $('<tr>');
    table.append(header_row);
    // col 1
    th1 = $('<th class="popup_table_header popup_checkbox_column">');
    table_checkbox = $('<input type="checkbox" class="popup_checkbox" id="global_table_checkbox" onchange="toggleTableCheckbox( \'__global\' );">');
    //table_checkbox = $('<input type="checkbox" id="global_table_checkbox" onchange="ttcbAction( \'__global\' );">');
    th1.append(table_checkbox);
    header_row.append(th1);
    // col 2
    th2 = $('<th class="popup_table_header">');
    th2.text('Table');
    header_row.append(th2);
    // col 3
    th3 = $('<th class="popup_table_header popup_radio_column">');
    th3.text('Ref');
    header_row.append(th3);

    //
    // now fill the table of tables to choose from
    //
    for (var i=0; i<config.file_list.length; i++){
        var table_name = config.file_list[i];
        var encoded_table_name = encode_name(table_name);
        body_row = $('<tr class="popup_chooser_height">');
        table.append(body_row);
        id = 'tbl_cb_'+encoded_table_name;
        var chosen_cked = '';
        if (config.active_file_list.indexOf(table_name) != -1){
            // previous table check to be enabled
            chosen_cked = 'checked';
            ttcbAction( table_name, true );
        }
        td1 = $('<td class="popup_chooser_cell"><input type="checkbox" class="table_checkboxes popup_checkbox" id="'+id+'" onchange="toggleTableCheckbox( \''+table_name+'\' );" '+chosen_cked+'></td>');
        body_row.append(td1);
        td2 = $('<td class="popup_chooser_cell">');
        td2.text(table_name);
        body_row.append(td2);
        ref_chkd = '';
        // Set first radio if first time through, else set when reference table encountered.
        if ((config.reference_table == '') && (i == 0)){
            ref_chkd='checked';
        }else if (table_name == config.reference_table){
            ref_chkd='checked';
        }
        // TODO maybe class this the same as row_checkboxes
        td3 = $('<td><input type="radio" value="'+table_name+'" name="tables_ref_group" '+ref_chkd+'/></td>');
        body_row.append(td3);
    }
}


// user wants a popup to choose rows from
function choose_rows(){
    fill_rows_area();
    $('#pickRowsModal').show();
    $('#rows_table').tableDnD({ onDragClass: "myDragClass" });
}


// fill in the 'Choose Rows' popup for the user
function fill_rows_area(){
    // Put something useful in the help icon
    help_icon = $('#row_help_icon');
    help_icon.attr('title','Checkbox selects,\n reorder rows top to bottom by dragging/dropping rows.');
    config._active_rows_map = {};
    var table = $('#rows_table');
    table.empty();
    //
    // make the header row
    //
    header_row = $('<tr>');
    table.append(header_row);
    // col 1
    th1 = $('<th class="popup_table_header popup_checkbox_column">');
    row_checkbox = $('<input type="checkbox" class="popup_checkbox" id="global_row_checkbox" onchange="toggleRowCheckbox( \'__global\' );">');
    th1.append(row_checkbox);
    header_row.append(th1);
    // col 2
    th2 = $('<th class="popup_table_header">');
    th2.text('Row Name');
    header_row.append(th2);
    // 2 cols in this table
    //
    // now fill the table
    //
    if (config.row_list.length == 0){
        // Picking rows before there are tables to show.  So user has seen no tables yet.
        // so just treat first table as reference and choose from them
        if (config.file_list.length == 0){
            report_status("There are no files listed in the config file at "+data_directory+'/'+config_file, 'ERROR');
             //$("#lynx_status").text("There are no files listed in the config file at "+data_directory+'/'+config_file);
             return;
        }
        table_name = config.file_list[0];
        // This call will initialize variables such as row_list since this first table is the reference table.
        // jsonify_contents( table_name, true );
        reset_col_and_row_lists(table_name);
    }
    for (var i=0; i<config.row_list.length; i++){
        var row_name = config.row_list[i];
        // skip showing first row to user since it is the header row
        if (row_name.trim().length == 0){continue;}
        var encoded_row_name = encode_name(row_name);
        body_row = $('<tr class="popup_chooser_height" >');
        table.append(body_row);
        id = 'row_cb_'+encoded_row_name;
        var chosen_cked = '';
        if (config.active_rows_list.indexOf(row_name) != -1){
            // previous row check to be enabled
            chosen_cked = 'checked';
            trcbAction( row_name, true );
        }
        td1 = $('<td class="popup_chooser_cell" ><input type="checkbox" class="row_checkboxes popup_checkbox" id="'+id+'" onchange="toggleRowCheckbox( \''+row_name+'\' );" '+chosen_cked+'></td>');
        body_row.append(td1);
        td2 = $('<td class="popup_chooser_cell" >');
        td2.text(row_name);
        body_row.append(td2);
    }
}


// user wants a popup to choose columns from
function choose_cols(){
    fill_columns_area();
    $('#pickColsModal').show();
    $('#columns_table').tableDnD({ onDragClass: "myDragClass" });
}


// fill in the 'Choose Columns' popup for the user
function fill_columns_area(){
    // Put something useful in the help icon
    help_icon = $('#column_help_icon');
    help_icon.attr('title','Checkbox selects a column,\n reorder columns left to right by dragging/dropping rows.');
    config._active_columns_map = {};
    var table = $('#columns_table');
    table.empty();
    //
    // make the header row
    //
    header_row = $('<tr>');
    table.append(header_row);
    // col 1
    th1 = $('<th class="popup_table_header popup_checkbox_column">');
    col_checkbox = $('<input type="checkbox" class="popup_checkbox" id="global_column_checkbox" onchange="toggleColumnCheckbox( \'__global\' );">');
    th1.append(col_checkbox);
    header_row.append(th1);
    // col 2
    th2 = $('<th class="popup_table_header">');
    th2.text('Column Name');
    header_row.append(th2);
    // 2 cols in this table
    //
    // now fill the table
    //
    if (config.column_list.length == 0){
        // Picking cols before there are tables to show.  So user has seen no tables yet.
        // so just treat first table as reference and choose from them
        if (config.file_list.length == 0){
            report_status("There are no files listed in the config file at "+data_directory+'/'+config_file, 'ERROR');
            // $("#lynx_status").text("There are no files listed in the config file at "+data_directory+'/'+config_file);
             return;
        }
        table_name = config.file_list[0];
        // This call will initialize variables such as column_list since this first table is the reference table.
        //jsonify_contents( table_name, true );
        reset_col_and_row_lists(table_name);
    }
    for (var i=0; i<config.column_list.length; i++){
        var column_name = config.column_list[i];
        // skip showing first row to user since it is the header row
        if (column_name.trim().length == 0){continue;}
        var encoded_column_name = encode_name(column_name);
        body_row = $('<tr class="popup_chooser_height">');
        table.append(body_row);
        id = 'column_cb_'+encoded_column_name;
        var chosen_cked = '';
        if (config.active_columns_list.indexOf(column_name) != -1){
            // previous col check to be enabled
            chosen_cked = 'checked';
            tccbAction( column_name, true ); // nothing further to do
        }
        td1 = $('<td class="popup_chooser_cell"><input type="checkbox" class="column_checkboxes popup_checkbox" id="'+id+'" onchange="toggleColumnCheckbox( \''+column_name+'\' );" '+chosen_cked+'></td>');
        body_row.append(td1);
        td2 = $('<td class="popup_chooser_cell">');
        td2.text(column_name);
        body_row.append(td2);
    }
}


function choose_help(){
    $('#helpModal').show();
}


// make the button to control a single table
// The div containing the items to hide or delete has the id [name]_div
function construct_table_controls( encoded_name, actual_name ){
    table_controls = $("<p class='table_control_area'>");
    var id_to_control = encoded_name;
    var btn_to_control = encoded_name+'_btn';
    tbl_btn = $('<button id="'+btn_to_control+'" class="table_button" onclick="tggl(\''+id_to_control+'\',\''+btn_to_control+'\' )">-</>');
    table_controls.append(tbl_btn);
    // now the table title
    table_controls.append('<p class="table_title">'+actual_name+'</p>');
    return table_controls;
}


// User is hiding or displaying a comparison table.
function tggl( ctrl_id, btn_id ){
    console.log('ctrl_id='+ctrl_id+', btn_id='+btn_id),
    txt = $("#"+btn_id).text();
    if (txt == '-'){
        $("#"+btn_id).text('+');
        $("#"+ctrl_id).hide();
    }else{
        $("#"+btn_id).text('-');
        $("#"+ctrl_id).show();
    }
}


// Make all the tables and their columns the same width.
function align_columns(){
    align_fixed_table_columns();
    align_scrollable_table_columns();
}


// Go through all the fixed tables and make them the same width.
// Since these tables have 1 column, just get the widest table width and apply to all.
function align_fixed_table_columns(){
    var fixed_table_width = 0;
    for (var i=0; i<config.active_fixed_table_list.length; i++){
        var t = config.active_fixed_table_list[i];
        var this_width = t.width();
        if (this_width > fixed_table_width){
            fixed_table_width = this_width;
        }
    }
    for (var i=0; i<config.active_fixed_table_list.length; i++){
        var t = config.active_fixed_table_list[i];
        t.width(fixed_table_width);
    }
}

// Go through the scrollable tables, making the column widths the same as the widest column in that position.
// Assumes all tables are showing the same # of columns.
function align_scrollable_table_columns(){
    // We take 1 off because the scrollable tables do not have column 0.
    // Column 0 is in the fixed table to the left of this table.
    num_cols = config.active_columns_list.length - 1;
    // following means there are no active columns, so bug out
    if (num_cols == -1){
        return;
    }
    config.width_list = Array.apply(null, Array(num_cols)).map(Number.prototype.valueOf, 0);
    // now iterate the tables and find widest column by looking at tr in first rows.
    for (var i=0; i<config.active_scroll_table_list.length; i++){
        var t = config.active_scroll_table_list[i];
        var rowz = t.find('tr');
        for (var j=0;j<config.active_rows_list.length; j++){
            this_row = rowz[j];
            if (j == 0){
                tdlist = $(this_row).find('th');
            }else{
                tdlist = $(this_row).find('td');
            }
            for (var k=0; k<config.width_list.length; k++){
                var td = $(tdlist[k]);
                var txt = td.text();
                w = get_text_width(txt);
                if (w > config.width_list[k]){
                    config.width_list[k] = w ;
                }
            }
        }
    }
    // Now get a total width for the tables.
    table_width = 0.0;
    for (var i=0; i<config.width_list.length; i++){
        cw = config.width_list[i];
        table_width += cw;
    }

    // Now iterate the tables again and set the column widths to the widest
    // values captured. Also set the table's entire width.
    for (var i=0; i<config.active_scroll_table_list.length; i++){
        var t = config.active_scroll_table_list[i];
        first_row = t.find("tr:first-child");
        tdlist = first_row.find('th');
        for (var j=0; j<config.width_list.length; j++){
            var td = $(tdlist[j]);
            var val = config.width_list[j];
            val += column_padding;
            setting = val.toString()+'px';
            td.width(setting);
        }
        t.width(table_width);
    }
    // Now, since we have fixed the leftmost column with position absolute,
    // we need to go down all the cells in the first column of all the tables and set the width.
    first_col_collection = $('td.row_header');
    var count = first_col_collection.length;
    var width = config.width_list[0];
    width += column_padding - 3; // for -3 explanation, see table_compare.css, td, padding-right
    width = Math.round(width);
    for (var i=0; i<first_col_collection.length; i++ ){
        td = $(first_col_collection[i]);
        td.width(width);
    }
}

// Given a set font and size, get the width in pixels of the text.
function get_text_width( text ){
    var metrics = context.measureText(text);
    return metrics.width;
}


// User needs col and/or row list before a reference table is detected, or when the reference table name changes.
function reset_col_and_row_lists( table_name ){
    config.row_list = [];
    config.column_list = [];
    // Clear active row list if appropriate.
    // Note that the active columns liste does not need this (see code below).
    if (config.rows_specified == false){
        config.active_rows_list = [];
    }
    var encoded_fl_name = encode_name(table_name);
    var blob = config.file_contents_map[encoded_fl_name];
    var lines = blob.split("\n");
    rows = lines.length;
    console.log('rows:'+rows);
    for (var row=0; row<rows; row++){
        var line = lines[row].split('|');
        if (row == 0){
            line.splice(0, 1); // remove HEADER tag from beginning
            line.unshift(' '); // replace it with a blank
            config.column_list = line;
            encode_column_names(line);
            if (config.columns_specified == false){config.active_columns_list = line;}
        }else{
            row_name = line[0].trim();
            encoded_row_name = encode_name(row_name);
            config.row_name_map[encoded_row_name] = row_name; // basically same as encode_column_names above, but for rows
        }
        var row_name = line[0];
        if (config.rows_specified == false){config.active_rows_list.push(row_name);}
        config.row_list.push(row_name); // see? we are rebuilding it now
    }
}


// Make an object out of the table.
function jsonify_contents( table_name ){
    var row = col = rows = cols = 0;
    var json = {};
    json.cell_list = [];
    json.row_names_list = [];
    json.column_names_list = [];
    // add blank cells for misses
    var cell = {};
    cell.data = "&nbsp;";
    cell.display_data = "&nbsp;";
    cell.orphan = true;
    json.orphan_cell = cell;
    var hdr_cell = {};
    hdr_cell.data = "&nbsp;";
    hdr_cell.display_data = "&nbsp;";
    hdr_cell.orphan = true;
    json.orphan_hdr_cell = hdr_cell;
    var encoded_fl_name = encode_name(table_name);
    var blob = config.file_contents_map[encoded_fl_name];
    var lines = blob.split("\n");
    rows = json.rows = lines.length;
    for (var row=0; row<rows; row++){
        var line = lines[row].split('|');
        if (row == 0){
            line.splice(0, 1); // remove HEADER tag from beginning
            line.unshift(' '); // replace it with a blank
            json.cols = cols = line.length;
            row_name = line[0]; // the blank we just unshifted onto the top
        }else{
            row_name = line[0].trim(); // TRIMMED
            json.row_names_list.push(row_name);
            encoded_row_name = encode_name(row_name);
            config.row_name_map[encoded_row_name] = row_name;
        }
        // now build cells as usual
        for (var col=0; col<cols; col++){
            cell = {};
            cell.orphan = false;
            cell.coloring_class = 'regular_colors';
            val = line[col];

            if ((col==0) && (row>0)){val = val.trim();} // TRIMMED
            if (row == 0){json.column_names_list.push(val);}
            var col_name = json.column_names_list[col]; // blank space in col 0, named otherwise

            // data is here for calculations needed for table state toggling
            cell.data = val;
            // display_data is displayed in the table cell, and is calculated based on table toggle state
            if (val.trim().length == 0){
                cell.display_data = '&nbsp;';
            }else{
                cell.display_data = val;
            }
            //cell.display_data = val;
            cell.row = row;cell.col = col;
            cell.row_name = row_name;cell.col_name = col_name;
            if ((row == 0) || (col == 0)){
                cell.coloring_class = 'header_colors';
            }
            json.cell_list.push(cell);
        }
    }
    return json;
}


// Lets us retrieve the original column name from the encoded version.
// Currently using this in only one place, and we should do the same with row names when we see them
// if we do this, anyway.
function encode_column_names( line ){
    for (var i=0; i<line.length; i++){
        nm = line[i];
        encoded = encode_name(nm);
        config.column_name_map[encoded] = nm;
    }
}


// Return the cell matching the row and column name,
// returning an orphan if not found.
function find_cell( json, row_name, col_name ){
    for (var i=0;i<json.cell_list.length; i++){
        cell = json.cell_list[i];
        if (cell.row_name == row_name){
            if (cell.col_name == col_name){
                return cell;
            }
        }
    }
    // we do not have that cell, so return the proper orphan
    if (row_name==" "){return json.orphan_hdr_cell;}
    if (col_name==" "){return json.orphan_hdr_cell;}
    return json.orphan_cell;
}


// User clicked one of the table choice checkboxes.
function toggleTableCheckbox( nm ){
    name = config.file_name_map[nm];
    if (nm == '__global'){
        // First off, since we are globally resetting, we are clearing the map now.
        // This lets us restore the display order.
        config._active_files_map = {};
        cb = $('#global_table_checkbox');
        state = cb.is(':checked');
        handle_global_table_state_change(state);
        other_checkboxes = $('.table_checkboxes');
        other_checkboxes.prop('checked', state); //.change();
    }else{ // user clicked an individual table checkbox, or we cascaded here due to change() above
        encoded_name = encode_name(nm);
        cb = $('#tbl_cb_'+encoded_name);
        state = cb.is(':checked');
        ttcbAction(nm, state);
    }
}


// User is either setting or unsetting all the table choices.
function handle_global_table_state_change( state ){
    if (state == false){
        //config.active_file_list = [];
        config._active_files_map = {};
    }else{
        // Clear list before rebuilding. Do not push a blank for column header row after clearing, it is added below.
        //config.active_file_list = [];
        for(var i=0; i<config.file_list.length; i++){
            nm = config.file_list[i];
            //config.active_file_list.push(nm);
            //encoded_name = encode_name(nm);
            ttcbAction(nm, true);
        }
    }
}

// the action to be done on a local check/uncheck in the tables area
// separate so we do not have to keep duplicate logic in toggleTableCheckbox and in fill_table_area
function ttcbAction( name, state ){
    if (state == true){
        config._active_files_map[name] = true;
    }else{
        delete config._active_files_map[name];
    }
}


// the action to be done on a local check/uncheck in the rows area
// separate so we do not have to keep duplicate logic in toggleRowCheckbox and in fill_table_area
function trcbAction( name, state ){
    if (state == true){
        config._active_rows_map[name] = true;
    }else{
        delete config._active_rows_map[name];
    }
}


// the action to be done on a local check/uncheck in the columns area
// separate so we do not have to keep duplicate logic in toggleColumnCheckbox and in fill_table_area
function tccbAction( name, state ){
    if (state == true){
        config._active_columns_map[name] = true;
    }else{
        delete config._active_columns_map[name];
    }
}

// User clicked one of the row choice checkboxes.
function toggleRowCheckbox ( nm ){
    name = config.file_name_map[nm];
    if (nm == '__global'){
        // First off, since we are globally resetting, we are clearing the map now.
        // This lets us restore the display order.
        config._active_rows_map = {};
        cb = $('#global_row_checkbox');
        state = cb.is(':checked');
        handle_global_row_state_change(state);
        other_checkboxes = $('.row_checkboxes');
        other_checkboxes.prop('checked', state); //.change();
    }else{ // user clicked an individual row checkbox
        encoded_name = encode_name(nm);
        cb = $('#row_cb_'+encoded_name);
        state = cb.is(':checked');
        trcbAction(nm, state);
    }
}


// User is either setting or unsetting all the row choices.
function handle_global_row_state_change( state ){
    if (state == false){
        // config.active_rows_list = [];
        // config.active_rows_list.push(" ");
        config._active_rows_map = {};
    }else{
        // Clear list before rebuilding. Do not push a blank for column header row after clearing, it is added below.
        //config.active_rows_list = [];
        for(var i=0; i<config.row_list.length; i++){
            nm = config.row_list[i];
            //encoded_name = encode_name(nm);
            trcbAction(nm, true);
        }
    }
}


// User clicked one of the column choice checkboxes.
function toggleColumnCheckbox( nm ){
    if (nm == '__global'){
        // First off, since we are globally resetting, we are clearing the map now.
        // This lets us restore the display order.
        config._active_columns_map = {};
        cb = $('#global_column_checkbox');
        state = cb.is(':checked');
        handle_global_column_state_change(state);
        other_checkboxes = $('.column_checkboxes');
        other_checkboxes.prop('checked', state); //.change();
    }else{ // user clicked an individual table checkbox
        encoded_name = encode_name(nm);
        cb = $('#column_cb_'+encoded_name);
        state = cb.is(':checked');
        tccbAction( nm, state );
    }
}


// User is either setting or unsetting all the column choices.
function handle_global_column_state_change( state ){
    if (state == false){
        //config.active_columns_list = [];
        //config.active_columns_list.push(" ");
        config._active_columns_map = {};
    }else{
        // Clear list before rebuilding. Do not push a blank for row header column after clearing, it is added below.
        //config.active_columns_list = [];
        for(var i=0; i<config.column_list.length; i++){
            nm = config.column_list[i];
            //encoded_name = encode_name(nm);
            tccbAction(nm, true);
        }
    }
}


// takes out illegal characters and replaces with underscore ('_')
// Used to create legal class names so we can find them later.
function encode_name( nm ){
    replaced = nm.toString().split('.').join('_');
    replaced =      replaced.split(' ').join('_');
    replaced =      replaced.split('/').join('_');
    replaced =      replaced.split('%').join('_');
    replaced =      replaced.split('?').join('_');
    replaced =      replaced.split('(').join('_'); // new from here down on 11/30/2018
    replaced =      replaced.split(')').join('_');
    replaced =      replaced.split('*').join('_');
    replaced =      replaced.split('@').join('_');
    replaced =      replaced.split('#').join('_');
    replaced =      replaced.split('^').join('_');
    replaced =      replaced.split('&').join('_');
    replaced =      replaced.split('+').join('_');
    replaced =      replaced.split('=').join('_');
    replaced =      replaced.split('!').join('_');
    replaced =      replaced.split('~').join('_');
    replaced =      replaced.split(':').join('_');
    replaced =      replaced.split(';').join('_');
    replaced =      replaced.split('{').join('_');
    replaced =      replaced.split('}').join('_');

    return replaced;
}


// OBSOLETE
// builds a grid of cell objects and fills it with the table body cells
function build_grid( json ){
   var r = json.rows;
   var c = json.cols;
    var grid = createArray( r, c );
    var cells = json.cell_list;
    for (var i=0; i<cells.length; i++){
        var cell = cells[i];
        var r = cell.row;
        var c = cell.col;
        grid[r][c] = cell;
    }
    return grid;
}


// OBSOLETE
function createArray(length) {
   var arr = new Array(length || 0),
       i = length;
   if (arguments.length > 1) {
       var args = Array.prototype.slice.call(arguments, 1);
       while(i--) arr[length-1 - i] = createArray.apply(this, args);
   }
   return arr;
}


// This is here because IE has no startsWith
if (!String.prototype.startsWith) {
  String.prototype.startsWith = function(searchString, position) {
    position = position || 0;
    return this.indexOf(searchString, position) === position;
  };
}


var check = function(){
    if(latched == false){
        console.log('returning from check')
        return;
    }
    else {
        setTimeout(check, 100);
    }
}


function report_status( line, mode ){
    if (mode == 'ERROR'){
        if (error_reported == true){return;}
        $("#lynx_status").text(line);
        error_reported = true;
    }
}

// failed RE stuff
//re_header = /^HEADER\\s*|.*$/g;
//re_header = /^HEADER\s*|.+$/g;
//pass1 = re_header.exec('HEADER|fleem');
//fail1 = re_header.exec('HEADE|');
//fail2 = re_header.exec('HEADER|');
