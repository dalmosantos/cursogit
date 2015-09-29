#git push origin --delete <branchName>
##Feature:
#integrador
git config --global push.default simple
git checkout -b develop
git push --set-upstream origin develop 
git checkout -b feat/feature1 develop
git push --set-upstream origin feat/feature1

#desenvolvedor - IDE
git config --global push.default simple
###NET
#Colocar condicional para validar mensagem de retorno (v2.0) – sem alterar a versão
#De:
# ...
# Ping();
# ...
# public void Ping()
# ...
# //#show results.
#            MessageBox.Show(output.ToString(), "result"); 
#Para: 
# ...
# MessageBox.Show(Ping().ToString());
# ...
# public Boolean Ping()
# ...
# if (output.ToString().Contains("Request timed out.") ||  output.ToString().Contains("Ping request could not find host ")) 
#            {
#                return false;
#            }
#            else
#            {
#                return true;
#            }
### Java
#De:
# ...
#            BufferedReader input = new BufferedReader(new InputStreamReader(pr.getInputStream()));
#
#            String line=null;      
#
#            while((line=input.readLine()) != null) {
#                System.out.println(line);
#            }
#
#            int exitVal = pr.waitFor();
#            System.out.println("Exited with error code "+exitVal);
# ...
#para 
#            int exitVal = pr.waitFor();
#            if (exitVal == 0)
#            {
#            	System.out.println("Host acessível!");
#            }
#            else
#            {
#            	System.out.println("Host inacessível!");
#            }

git commit
git push

#Development:
git checkout develop
#Alterar o botão de teste para Ping
#Java colocar ...ping " + args[0]
git commit
git push --set-upstream origin develop 

#atualização feature com develop
git checkout feat/feature1
git merge develop
git push

# merge feature develop
git checkout develop
git merge feat/feature1
git push

##integrador
# release branch
git branch -d feat/feature1
git checkout -b release/2.0.0 develop
git push --set-upstream origin release/2.0.0

# release prd
git checkout master
git merge release/2.0.0
git push
git checkout develop
git branch -d release/2.0.0
git tag -a 2.0.0 -m "Release 2.0.0"
git push --follow-tags

#Hotfix:
#integrador
git checkout -b hotfix/fix1 master
git push --set-upstream origin hotfix/fix1
#Ajustar a versao para 2.0
git commit
git push
#merge master
git checkout master
git pull
git merge hotfix/fix1
git push
git branch -d hotfix/fix1
git tag -a 2.0.1 -m "Release 2.0.1"
git push --follow-tags