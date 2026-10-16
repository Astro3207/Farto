import java.io.*;
import java.nio.charset.StandardCharsets;
import java.nio.file.*;
import net.sourceforge.kolmafia.KoLmafia;
import net.sourceforge.kolmafia.RequestLogger;
import net.sourceforge.kolmafia.textui.AshRuntime;

// Offline only: all game state and combat actions are mocked.
class ValidateReplacements {
 static AshRuntime parse(String source) {
  AshRuntime runtime = new AshRuntime();
  if (!runtime.validate(null, new ByteArrayInputStream(source.getBytes(StandardCharsets.UTF_8))))
   throw new AssertionError(runtime.getParser().getDiagnostics());
  return runtime;
 }
 public static void main(String[] args) throws Exception {
  String iotm=Files.readString(Path.of(args[0],"scripts/iotm.ash"));
  String ccs=Files.readString(Path.of(args[0],"scripts/unlockerCCS.ash"));
  int branch=ccs.indexOf("    if (get_property(\"subscript\") == \"replacementChain\"");
  String helper=iotm.substring(iotm.indexOf("    skill nextReplacement()"), iotm.indexOf("    // Mafia state snapshot"))
      + "void replaceFreeMonster(){\n" + ccs.substring(branch,ccs.indexOf("    print (\"monster hp",branch)) + "}\n";
  for(String fn:new String[]{"get_property","available_amount","have_skill","my_location","last_monster","use_skill","abort"})
   helper=helper.replaceAll("\\b"+fn+"\\(","test_"+fn+"(");
  String mocks="""
    monster copyTarget = $monster[Black Crayon Mer-kin];
    string[string] props;
    boolean glove = true;
    boolean skillKnown = true;
    boolean wrongResult;
    int used;
    string failure;
    monster enemy = $monster[crate];
    location place = $location[Noob Cave];
    string test_get_property(string key) { return props[key]; }
    int test_available_amount(item it) { return glove ? 1 : 0; }
    boolean test_have_skill(skill sk) { return skillKnown; }
    location test_my_location() { return place; }
    monster test_last_monster() { return enemy; }
    void test_abort(string message) { failure=message; abort(message); }
    boolean test_use_skill(skill sk) {
      used += 1;
      string counter = sk == $skill[Macrometeorite] ? "_macrometeoriteUses" : "_powerfulGloveBatteryPowerUsed";
      props[counter] = props[counter].to_int() + (sk == $skill[Macrometeorite] ? 1 : 10);
      enemy = wrongResult ? $monster[crate] : copyTarget;
      return true;
    }
    void check(boolean ok, string message) { if (!ok) abort("FAIL: " + message); }
    void setup() {
      props["script"]="FreeKill";
      props["subscript"]="replacementChain";
      props["beGregariousMonster"]=copyTarget;
      props["beGregariousFightsLeft"]="1";
      props["_monsterHabitatsRecalled"]="3";

    }
    """;
  String normal="""
    void main() {
      setup();
      check(nextReplacement() != $skill[none], "reserve final source");
      props["beGregariousFightsLeft"]="2";
      check(nextReplacement() == $skill[none], "do not reserve earlier copies");
      props["beGregariousFightsLeft"]="1";
      props["beGregariousMonster"]="crate";
      check(nextReplacement() == $skill[none], "wrong source monster");
      props["beGregariousMonster"]=copyTarget;
      props["_macrometeoriteUses"]="10";
      check(nextReplacement() != $skill[Macrometeorite], "meteor cap");
      props["_powerfulGloveBatteryPowerUsed"]="90";
      check(nextReplacement() == $skill[CHEAT CODE: Replace Enemy], "last glove charge");
      props["_powerfulGloveBatteryPowerUsed"]="91";
      check(nextReplacement() == $skill[none], "insufficient glove battery");
      glove=false;
      props["_powerfulGloveBatteryPowerUsed"]="0";
      check(nextReplacement() == $skill[none], "missing glove");
      glove=true;
      skillKnown=false;
      check(nextReplacement() != $skill[Macrometeorite], "missing meteor lore");
      skillKnown=true;
      props["_macrometeoriteUses"]="0";
      replaceFreeMonster();
      check(used==1 && enemy==copyTarget, "crate replaced into configured target");
      replaceFreeMonster();
      check(used==1, "do not replace the target");
      copyTarget=$monster[sausage goblin];
      props["beGregariousMonster"]=copyTarget;
      enemy=$monster[crate];
      props["_macrometeoriteUses"]="10";
      replaceFreeMonster();
      check(used==2 && enemy==copyTarget && props["_powerfulGloveBatteryPowerUsed"]=="10", "glove uses shared changed target");
      props["beGregariousFightsLeft"]="0";
      props["_monsterHabitatsMonster"]=copyTarget;
      props["_monsterHabitatsFightsLeft"]="1";
      check(nextReplacement() != $skill[none], "last habitat copy");
      print("PASS normal");
    }
    """;
  run(mocks+helper+normal,"normal");
  for(String scenario:new String[]{"unexpected","no-source","wrong-result"}) {
   String setup=switch(scenario) {
    case "unexpected" -> "enemy=$monster[spooky vampire];";
    case "no-source" -> "props[\"beGregariousFightsLeft\"]=\"0\";";
    default -> "wrongResult=true;";
   };
   int expected=scenario.equals("unexpected")||scenario.equals("no-source")?0:1;
   String code="void main(){setup();"+setup+"try{replaceFreeMonster();}finally{if(failure!=\"\" && used=="+expected+")print(\"PASS "+scenario+"\");}}";
   run(mocks+helper+code,scenario);
  }
  String sm=Files.readString(Path.of(args[0],"scripts/StockingMimic.ash"));
  String driver=("void testReplacementLoop(){" + sm.substring(sm.indexOf("    if (nextReplacement() == $skill[none]) return;"),sm.indexOf("void mimicEgg()")))
      .replace("main@preadventure();","mimicPrep();");
  for(String fn:new String[]{"get_property","set_property","get_auto_attack","set_auto_attack","total_turns_played","current_round","handling_choice","adv1","abort"})
   driver=driver.replaceAll("\\b"+fn+"\\(","test_"+fn+"(");
  String driverMocks="""
    int autoattack=99;
    int turns;
    string scenario;
    boolean finished;
    void step(string message) {}
    void mimicPrep() {}
    void habitatRecall() { finished=true; }
    void test_set_property(string key,string value) { props[key]=value; }
    int test_get_auto_attack() { return autoattack; }
    void test_set_auto_attack(int value) { autoattack=value; }
    int test_total_turns_played() { return turns; }
    int test_current_round() { return 0; }
    boolean test_handling_choice() { return false; }
    boolean test_adv1(location loc) {
      check(autoattack==0 && props["subscript"]=="replacementChain", "Prepare before adventure");
      if(scenario=="unfinished") return false;
      if(scenario=="paid") turns+=1;
      if(scenario=="original") props["beGregariousFightsLeft"]="0";
      else if(scenario!="stalled") props["_powerfulGloveBatteryPowerUsed"]="100";
      return true;
    }
    """;
  for(String scenario:new String[]{"exhausted","original","stalled","paid","unfinished"}) {
   boolean failure=scenario.equals("stalled")||scenario.equals("paid")||scenario.equals("unfinished");
   String code="void main(){setup(); scenario=\""+scenario+"\"; props[\"_macrometeoriteUses\"]=\"10\"; props[\"_powerfulGloveBatteryPowerUsed\"]=\"90\"; props[\"subscript\"]=\"saved\"; props[\"acc3Override\"]=\"saved accessory\"; try{testReplacementLoop();}finally{check(autoattack==99 && props[\"subscript\"]==\"\" && props[\"acc3Override\"]==\"\",\"Restore state\"); check((failure!=\"\")=="+failure+" && finished=="+!failure+",\"Finish or stop\"); print(\"PASS driver-"+scenario+"\");}}";
   run(mocks+helper+driverMocks+driver+code,"driver-"+scenario);
  }
  if(sm.split("backup\\(\\);",-1).length!=3 || sm.contains("void monsterReplacements"))
   throw new AssertionError("Both daily routes must use the existing backup phase");
  if(sm.indexOf("phase: bulkFK monster replacements") < sm.indexOf("void backup()")
      || sm.indexOf("phase: bulkFK monster replacements") > sm.indexOf("void mimicEgg()"))
   throw new AssertionError("Replacements must be inside the backup phase");
  System.out.println("Replacement policy, action guards, counters, target changes, and phase placement passed.");
 }
 static void run(String source,String label) {
  KoLmafia.forceContinue();
  ByteArrayOutputStream output=new ByteArrayOutputStream();
  RequestLogger.openCustom(new PrintStream(output));
  parse(source).execute("main",new Object[0]);
  String log=output.toString(StandardCharsets.UTF_8);
  if(!log.contains("PASS "+label)) throw new AssertionError(log);
  System.out.println("PASS "+label);
 }
}
