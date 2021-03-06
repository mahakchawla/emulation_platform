import esdl.base;
import uvm;
import std.stdio;
import esdl.intf.vpi;
import std.string: format;

enum COUNT = 1;

@UVM_DEFAULT
class avl_st: uvm_sequence_item
{

  version(UVM_NORANDOM) {
    ubyte data;
  }
  else {
    @rand ubyte data;
  }
  bool start;
  bool end;

  mixin uvm_object_utils;
   
  this(string name = "avl_st") {
    super(name);
  }

  version(UVM_NORANDOM) {}
  else {
    Constraint! q{
      data >= 0x30;
      data <= 0x7a;
    } cst_ascii;
  }
  // override public string convert2string() {
  //   if(kind == kind_e.WRITE)
  //     return format("kind=%s addr=%x wdata=%x",
  // 		    kind, addr, wdata);
  //   else
  //     return format("kind=%s addr=%x rdata=%x",
  // 		    kind, addr, rdata);
  // }

  // void postRandomize() {
  //   // writeln("post_randomize: ", this.convert2string);
  // }
}

class avl_st_seq: uvm_sequence!avl_st
{
  avl_st req;
  avl_st rsp;
  mixin uvm_object_utils;

  version(UVM_NORANDOM) {
    uint seq_size;
  }
  else {
    @rand uint seq_size;
  }

  this(string name="") {
    super(name);
    req = avl_st.type_id.create(name ~ ".req");
  }

  version(UVM_NORANDOM) {}
  else {
    Constraint!q{
      seq_size == 256;
      seq_size > 32;
    } seq_size_cst;
  }
  // task
  override void frame() {
    uvm_info("avl_st_seq", "Starting sequence", UVM_MEDIUM);

    // atomic sequence
    // uvm_create(req);

    for (size_t i=0; i!=seq_size; ++i) {
      // req.randomize();
      if(i == 0) {req.start = true;}
      else {req.start = false;}
      if(i == seq_size - 1) {req.end = true;}
      else {req.end = false;}
      avl_st cloned = cast(avl_st) req.clone;
      uvm_send(cloned);
      get_response(rsp);
    }
    
    uvm_info("avl_st", "Finishing sequence", UVM_MEDIUM);
  } // frame

}

class avl_st_driver_cbs: uvm_callback
{
  void trans_received (avl_st_driver xactor , avl_st cycle) {}
  void trans_executed (avl_st_driver xactor , avl_st cycle) {}
}

class avl_st_driver: uvm_driver!avl_st
{

  mixin uvm_component_utils;
  
  uvm_put_port!avl_st egress;
  uvm_get_port!avl_st ingress;
  
  // override void build_phase(uvm_phase phase) {
  //   egress = new uvm_put_port!avl_st("egress", this);
  //   ingress = new uvm_get_port!avl_st("ingress", this);
  // }

  Event trig;
  // avl_st_vif sigs;
  // avl_st_config cfg;

  this(string name, uvm_component parent = null) {
    super(name,parent);
  }
   
  override void run_phase(uvm_phase phase) {
    super.run_phase(phase);

    while(true) {
      avl_st req;
      avl_st rsp;

      
      seq_item_port.get_next_item(req);

      // push the transaction
      // ....
      // egress.put(req);

      // this.trans_received(req);
      // uvm_do_callbacks(avl_st_driver,avl_st_driver_cbs,trans_received(this,req));
         
      // get the reponse
      // ingress.get(rsp);
      // req.print();
      rsp = cast(avl_st) req.clone;
      rsp.set_id_info(req);

      // writeln(rsp.convert2string());
      
      // this.trans_executed(req);
      // uvm_do_callbacks(avl_st_driver,avl_st_driver_cbs,trans_executed(this,req));

      seq_item_port.item_done(rsp);

      // trig.notify();
    }
  }

  override void final_phase(uvm_phase phase) {
    egress.put(null);
  }

  protected void trans_received(avl_st tr) {}
    
 
  protected void trans_executed(avl_st tr) {}

}

class avl_st_sequencer: uvm_sequencer!avl_st
{
  mixin uvm_component_utils;

  this(string name, uvm_component parent=null) {
    super(name, parent);
  }
}

class avl_st_agent: uvm_agent
{

  avl_st_sequencer sequencer;
  avl_st_driver    driver;
  // avl_st_monitor   mon;

  // avl_st_vif       vif;

  mixin uvm_component_utils;
   
  this(string name, uvm_component parent = null) {
    super(name, parent);
  }

  // override void build_phase(uvm_phase phase) {
  //   sequencer = avl_st_sequencer.type_id.create("sequencer", this);
  //   driver = avl_st_driver.type_id.create("driver", this);
  //   // mon = avl_st_monitor::type_id::create("mon", this);
  // }

  override void connect_phase(uvm_phase phase) {
    driver.seq_item_port.connect(sequencer.seq_item_export);
  }
}

class avl_st_env: uvm_env
{
  mixin uvm_component_utils;
  private avl_st_agent agent;

  this(string name, uvm_component parent) {
    super(name, parent);
  }

  void start_sequence(avl_st_seq sequence) {
	sequence.start(agent.sequencer, null);
  }
    
  // task
  override void run_phase(uvm_phase phase) {
    phase.raise_objection(this);

    for (size_t i=0; i!=100; ++i) {
      auto sequence = new avl_st_seq(format("sequence[%s]", i));
      version(UVM_NORANDOM) {}
      else {
	sequence.randomize();
      }
      writeln("Generated ", i,
 " seq with ", sequence.seq_size, " transactions");
      start_sequence(sequence);
    }
    
    // waitForks();
    
    phase.drop_objection(this);
  }
};

class avl_st_root: uvm_root
{
  mixin uvm_component_utils;
  avl_st_env env;

  uvm_tlm_fifo_egress!avl_st[COUNT] fifo_out;
  uvm_tlm_fifo_ingress!avl_st[COUNT] fifo_in;

  uvm_get_port!avl_st[COUNT] ingress;
  uvm_put_port!avl_st[COUNT] egress;

  override void initial() {
    set_timeout(0.nsec, false);
    // for (size_t i=0; i!=COUNT; ++i)
    //   {
    // 	ingress[i] = new uvm_get_port!avl_st(format("ingress[%s]", i), this);
    // 	egress[i] = new uvm_put_port!avl_st(format("egress[%s]", i), this);

    // 	fifo_out[i] = new uvm_tlm_fifo_egress!avl_st(format("fifo_out[%s]", i),
    // 						     null, 1);
    // 	fifo_in[i] = new uvm_tlm_fifo_ingress!avl_st(format("fifo_in[%s]", i),
    // 						     null, 1);

    //   }
    // env = new avl_st_env("env", null);
    run_test();
  }
  override void connect_phase(uvm_phase phase) {

    for (size_t i=0; i!=COUNT; ++i)
      {
	env.agent.driver.egress.connect(fifo_out[i].put_export);
	env.agent.driver.ingress.connect(fifo_in[i].get_export);
	ingress[i].connect(fifo_out[i].get_export);
	egress[i].connect(fifo_in[i].put_export);
      }
  }
}

class TestBench: RootEntity
{
  uvm_root_entity!(avl_st_root) tb;
  // uvm_root_entity!(avl_st_root) tb2;
  // public override void doFinish() {
  //   foreach(p; tb.get_root().fifo_out) {
  //     p.put(null);
  //   }
  //   foreach(p; tb2.get_root().fifo_out) {
  //     p.put(null);
  //   }
    
  // }
}


void main()
{
  import std.random: uniform;
  import std.stdio;

  TestBench test = new TestBench;
  test.multiCore(2, 0);
  test.elaborate("test");
  test.tb.set_seed(100);
  // test.tb2.set_seed(101);
  test.simulate();

}

