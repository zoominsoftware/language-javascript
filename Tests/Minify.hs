module Tests.Minify
    ( testMinifyExpr
    , testMinifyStmt
    ) where

import Control.Monad (forM_)
import Test.Hspec

import Language.JavaScript.Parser
import Language.JavaScript.Parser.Grammar5
import Language.JavaScript.Parser.Parser
import Language.JavaScript.Process.Minify


testMinifyExpr :: Spec
testMinifyExpr = describe "Minify expressions:" $ do
    it "terminals" $ do
        minifyExpr " identifier " `shouldBe` "identifier"
        minifyExpr " 1 " `shouldBe` "1"
        minifyExpr " this " `shouldBe` "this"
        minifyExpr " 0x12ab " `shouldBe` "0x12ab"
        minifyExpr " 0567 " `shouldBe` "0567"
        minifyExpr " 'helo' " `shouldBe` "'helo'"
        minifyExpr " \"good bye\" " `shouldBe` "\"good bye\""
        minifyExpr " /\\n/g " `shouldBe` "/\\n/g"

    it "array literals" $ do
        minifyExpr " [ ] " `shouldBe` "[]"
        minifyExpr " [ , ] " `shouldBe` "[,]"
        minifyExpr " [ , , ] " `shouldBe` "[,,]"
        minifyExpr " [ x ] " `shouldBe` "[x]"
        minifyExpr " [ x , y ] " `shouldBe` "[x,y]"

    it "parentheses" $ do
        minifyExpr " ( 'hello' ) " `shouldBe` "('hello')"
        minifyExpr " ( 12 ) " `shouldBe` "(12)"
        minifyExpr " ( 1 + 2 ) " `shouldBe` "(1+2)"

    it "unary" $ do
        minifyExpr " a -- " `shouldBe` "a--"
        minifyExpr " delete b " `shouldBe` "delete b"
        minifyExpr " c ++ " `shouldBe` "c++"
        minifyExpr " - d " `shouldBe` "-d"
        minifyExpr " ! e " `shouldBe` "!e"
        minifyExpr " + f " `shouldBe` "+f"
        minifyExpr " ~ g " `shouldBe` "~g"
        minifyExpr " typeof h " `shouldBe` "typeof h"
        minifyExpr " void i " `shouldBe` "void i"

    it "binary" $ do
        minifyExpr " a && z " `shouldBe` "a&&z"
        minifyExpr " b & z " `shouldBe` "b&z"
        minifyExpr " c | z " `shouldBe` "c|z"
        minifyExpr " d ^ z " `shouldBe` "d^z"
        minifyExpr " e / z " `shouldBe` "e/z"
        minifyExpr " f == z " `shouldBe` "f==z"
        minifyExpr " g >= z " `shouldBe` "g>=z"
        minifyExpr " h > z " `shouldBe` "h>z"
        minifyExpr " i in z " `shouldBe` "i in z"
        minifyExpr " j instanceof z " `shouldBe` "j instanceof z"
        minifyExpr " k <= z " `shouldBe` "k<=z"
        minifyExpr " l << z " `shouldBe` "l<<z"
        minifyExpr " m < z " `shouldBe`  "m<z"
        minifyExpr " n - z " `shouldBe`  "n-z"
        minifyExpr " o % z " `shouldBe`  "o%z"
        minifyExpr " p != z " `shouldBe`  "p!=z"
        minifyExpr " q || z " `shouldBe`  "q||z"
        minifyExpr " r + z " `shouldBe`  "r+z"
        minifyExpr " s >> z " `shouldBe`  "s>>z"
        minifyExpr " t === z " `shouldBe`  "t===z"
        minifyExpr " u !== z " `shouldBe`  "u!==z"
        minifyExpr " v * z " `shouldBe`  "v*z"
        minifyExpr " w >>> z " `shouldBe`  "w>>>z"

    it "ternary" $ do
        minifyExpr "  true ? 1 : 2 " `shouldBe` "true?1:2"
        minifyExpr "  x ? y + 1 : j - 1 " `shouldBe` "x?y+1:j-1"

    it "member access" $ do
        minifyExpr " a . b " `shouldBe` "a.b"
        minifyExpr " c . d . e " `shouldBe` "c.d.e"

    it "new" $ do
        minifyExpr " new f ( ) " `shouldBe` "new f()"
        minifyExpr " new g ( 1 ) " `shouldBe` "new g(1)"
        minifyExpr " new h ( 1 , 2 ) " `shouldBe` "new h(1,2)"
        minifyExpr " new k . x " `shouldBe` "new k.x"

    it "array access" $ do
        minifyExpr " i [ a ] " `shouldBe` "i[a]"
        minifyExpr " j [ a ] [ b ]" `shouldBe` "j[a][b]"

    it "function" $ do
        minifyExpr " function ( ) { } " `shouldBe` "function(){}"
        minifyExpr " function ( a ) { } " `shouldBe` "function(a){}"
        minifyExpr " function ( a , b ) { return a + b ; } " `shouldBe` "function(a,b){return a+b}"

    it "calls" $ do
        minifyExpr " a ( ) " `shouldBe` "a()"
        minifyExpr " b ( ) ( ) " `shouldBe` "b()()"
        minifyExpr " c ( ) [ x ] "  `shouldBe` "c()[x]"
        minifyExpr " d ( ) . y " `shouldBe` "d().y"

    it "property accessor" $ do
        minifyExpr " { get foo ( ) { return x } } " `shouldBe` "{get foo(){return x}}"
        minifyExpr " { set foo ( a ) { x = a } } " `shouldBe` "{set foo(a){x=a}}"


testMinifyStmt :: Spec
testMinifyStmt = describe "Minify statements:" $ do
    forM_ [ "break", "continue", "return" ] $ \kw ->
        it kw $ do
            minifyStmt (" " ++ kw ++ " ; ") `shouldBe` kw
            minifyStmt (" {" ++ kw ++ " ;} ") `shouldBe` kw
            minifyStmt (" " ++ kw ++ " x ; ") `shouldBe` (kw ++ " x")
            minifyStmt ("\n\n" ++ kw ++ " x ;\n") `shouldBe` (kw ++ " x")

    it "block" $ do
        minifyStmt "\n{ a = 1\nb = 2\n } " `shouldBe` "{a=1;b=2}"
        minifyStmt " { c = 3 ; d = 4 ; } " `shouldBe` "{c=3;d=4}"

    it "if" $ do
        minifyStmt " if ( 1 ) return ; " `shouldBe` "if(1)return"
        minifyStmt " if ( 1 ) ; " `shouldBe` "if(1);"

    it "if/else" $ do
        minifyStmt " if ( 1 ) ; else break ; " `shouldBe` "if(1){return}else break"
        minifyStmt " if ( 1 ) break ; else break ; " `shouldBe` "if(1){break}else break"
        minifyStmt " if ( 1 ) continue ; else continue ; " `shouldBe` "if(1){continue}else continue"
        minifyStmt " if ( 1 ) return ; else return ; " `shouldBe` "if(1){return}else return"

    it "while" $ do
        minifyStmt " while ( x < 2 ) x ++ ; " `shouldBe` "while(x<2)x++"
        minifyStmt " while ( x < 0x12 && y > 1 ) { x *= 3 ; y += 1 ; } ; " `shouldBe` "while(x<0x12&&y>1){x*=3;y+=1}"

    it "do/while" $ do
        minifyStmt " do x = foo (y) ; while ( x < y ) ; " `shouldBe` "do{x=foo(y)}while(x<y)"
        minifyStmt " do { x = foo (x, y) ; y -- ; } while ( x > y ) ; " `shouldBe` "do{x=foo(x,y);y--}while(x>y)"

    it "for" $ do
        minifyStmt " for ( ; ; ) ; " `shouldBe` "for(;;);"
        minifyStmt " for ( k = 0 ; k <= 10 ; k ++ ) ; " `shouldBe` "for(k=0;k<=10;k++);"
        minifyStmt " for ( k = 0, j = 1 ; k <= 10 && j < 10 ; k ++ , j -- ) ; " `shouldBe` "for(k=0,j=1;k<=10&&j<10;k++,j--);"
        minifyStmt " for (var x ; y ; z) { } " `shouldBe` "for(var x;y;z){}"
        minifyStmt " for ( x in 5 ) foo (x) ;" `shouldBe` "for(x in 5)foo(x)"
        minifyStmt " for ( var x in 5 ) { foo ( x++ ); y ++ ; } ;" `shouldBe` "for(var x in 5){foo(x++);y++}"

    it "labelled" $ do
        minifyStmt " start : while ( true ) { if ( i ++ < 3 ) continue start ; break ; } ; " `shouldBe` "start:while(true){if(i++<3)continue start;break}"
        minifyStmt " { k ++ ; start : while ( true ) { if ( i ++ < 3 ) continue start ; break ; } ; } ; " `shouldBe` "{k++;start:while(true){if(i++<3)continue start;break}}"

    it "function" $ do
        minifyStmt " function f ( ) { } ; " `shouldBe` "function f(){}"
        minifyStmt " function f ( a ) { } ; " `shouldBe` "function f(a){}"
        minifyStmt " function f ( a , b ) { return a + b ; } ; " `shouldBe` "function f(a,b){return a+b}"

    it "with" $ do
        minifyStmt " with ( x ) { } ; " `shouldBe` "with(x){}"
        minifyStmt "    with({ first: 'John' }) { foo ('Hello '+first); }" `shouldBe` "with({first:'John'}){foo('Hello '+first)}"

    it "throw" $ do
        minifyStmt " throw a " `shouldBe` "throw a"
        minifyStmt " throw b ; " `shouldBe` "throw b"
        minifyStmt " { throw c ; } ;" `shouldBe` "throw c"

    it "switch" $ do
        minifyStmt " switch ( a ) { } ; " `shouldBe` "switch(a){}"
        minifyStmt " switch ( b ) { case 1 : case 'a': case \"b\" : break ; default : break ; } ; " `shouldBe` "switch(b){case 1:case'a':case\"b\":break;default:break;}"

    it "try/catch/finally" $ do
        minifyStmt " try { } catch ( a ) { } " `shouldBe` "try{}catch(a){}"
        minifyStmt " try { b } finally { } " `shouldBe` "try{b}finally{}"
        minifyStmt " try { } catch ( c ) { } finally { } " `shouldBe` "try{}catch(c){}finally{}"
        minifyStmt " try { } catch ( d ) { } catch ( x ){ } finally { } " `shouldBe` "try{}catch(d){}catch(x){}finally{}"
        minifyStmt " try { } catch ( e ) { } catch ( y ) { } " `shouldBe` "try{}catch(e){}catch(y){}"
        minifyStmt " try { } catch ( f  if true ) { } catch ( z ) { } " `shouldBe` "try{}catch(fiftrue){}catch(z){}"

    it "variable declaration" $ do
        minifyStmt " var a  " `shouldBe` "var a"
        minifyStmt " var b ; " `shouldBe` "var b"
        minifyStmt " var c = 1 ; " `shouldBe` "var c=1"
        minifyStmt " var d = 1, x = 2 ; " `shouldBe` "var d=1,x=2"

-- -----------------------------------------------------------------------------
-- Minify test helpers.

minifyExpr :: String -> String
minifyExpr str = either id (renderToString . minifyJS) (parseUsing parseExpression str "src")

minifyStmt :: String -> String
minifyStmt str = either id (renderToString . minifyJS) (parseUsing parseStatement str "src")
