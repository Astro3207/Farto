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
  String helper=Files.readString(Path.of(args[0],"scripts/freeMonsterReplacements.ash"));
  helper=helper.substring(helper.indexOf("boolean replacementSourceReady()"));
  for(String fn:new String[]{"get_property","available_amount","have_skill","my_location","last_monster","use_skill","abort"})
   helper=helper.replaceAll("\\b"+fn+"\\(","test_"+fn+"(");
  String mocks="""
    monster copyTarget = $monster[Black Crayon Mer-kin];
    string[string] props;
    boolean glove = true;
    boolean skillKnown = true;
    boolean advance = true;
    boolean wrongResult;
    int used;
    string failure;
    monster enemy = $monster[crate];
    location place = $location[Noob Cave];
    int dayType() { return 1; }
    string test_get_property(string key) { return props[key]; }
    int test_available_amount(item it) { return glove ? 1 : 0; }
    boolean test_have_skill(skill sk) { return skillKnown; }
    location test_my_location() { return place; }
    monster test_last_monster() { return enemy; }
    void test_abort(string message) { failure=message; abort(message); }
    boolean test_use_skill(skill sk) {
      used += 1;
      string counter = sk == $skill[Macrometeorite] ? "_macrometeoriteUses" : "_powerfulGloveBatteryPowerUsed";
      if (advance) props[counter] = props[counter].to_int() + (sk == $skill[Macrometeorite] ? 1 : 10);
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
      props["fartoReplacementSkill"]="Macrometeorite";
    }
    """;
  String normal="""
    void main() {
      setup();
      check(reserveReplacementSource(), "reserve final source");
      props["beGregariousFightsLeft"]="2";
      check(!replacementSourceReady(), "do not reserve earlier copies");
      props["beGregariousFightsLeft"]="1";
      props["beGregariousMonster"]="crate";
      check(!replacementSourceReady(), "wrong source monster");
      props["beGregariousMonster"]=copyTarget;
      props["_macrometeoriteUses"]="10";
      check(!replacementReady($skill[Macrometeorite]), "meteor cap");
      props["_powerfulGloveBatteryPowerUsed"]="90";
      check(replacementReady($skill[CHEAT CODE: Replace Enemy]), "last glove charge");
      props["_powerfulGloveBatteryPowerUsed"]="91";
      check(!replacementReady($skill[CHEAT CODE: Replace Enemy]), "insufficient glove battery");
      glove=false;
      props["_powerfulGloveBatteryPowerUsed"]="0";
      check(!replacementReady($skill[CHEAT CODE: Replace Enemy]), "missing glove");
      glove=true;
      skillKnown=false;
      check(!replacementReady($skill[Macrometeorite]), "missing meteor lore");
      skillKnown=true;
      props["_macrometeoriteUses"]="0";
      replaceFreeMonster();
      check(used==1 && enemy==copyTarget, "crate replaced into configured target");
      replaceFreeMonster();
      check(used==1, "do not replace the target");
      copyTarget=$monster[sausage goblin];
      props["beGregariousMonster"]=copyTarget;
      enemy=$monster[crate];
      props["fartoReplacementSkill"]="CHEAT CODE: Replace Enemy";
      replaceFreeMonster();
      check(used==2 && enemy==copyTarget && props["_powerfulGloveBatteryPowerUsed"]=="10", "glove uses shared changed target");
      props["beGregariousFightsLeft"]="0";
      props["_monsterHabitatsMonster"]=copyTarget;
      props["_monsterHabitatsFightsLeft"]="1";
      check(replacementSourceReady(), "last habitat copy");
      print("PASS normal");
    }
    """;
  run(mocks+helper+normal,"normal");
  for(String scenario:new String[]{"unexpected","no-source","no-progress","wrong-result"}) {
   String setup=switch(scenario) {
    case "unexpected" -> "enemy=$monster[spooky vampire];";
    case "no-source" -> "props[\"beGregariousFightsLeft\"]=\"0\";";
    case "no-progress" -> "advance=false;";
    default -> "wrongResult=true;";
   };
   int expected=scenario.equals("unexpected")||scenario.equals("no-source")?0:1;
   String code="void main(){setup();"+setup+"try{replaceFreeMonster();}finally{if(failure!=\"\" && used=="+expected+")print(\"PASS "+scenario+"\");}}";
   run(mocks+helper+code,scenario);
  }
  String sm=Files.readString(Path.of(args[0],"scripts/StockingMimic.ash"));
  if(sm.split("backup\\(\\);\\s*monsterReplacements\\(\\);",-1).length!=3)
   throw new AssertionError("Both daily routes must run replacements directly after backups");
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
