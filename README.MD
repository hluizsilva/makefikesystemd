# Criar serviço em ambiente Linux

O arquivo de configuração .service possui as informações sobre um processo controlado e supervisionado pelo systemd.

## Detalhando o arquivo .service
Os itens de configuração comuns serão configurados na seções genericas **\[Unit\]** e **\[Install\]**, as configruações especificas serão configuradas na seção **\[Service\]**.
Abaixo será detalhado as principais chaves e parâmetros deste arquivo.

Quando é chamado um serviço com um determinado nome, mas nunhum arquivo de configuração de unit for encontrado, o systemd procurará um script init do SysV com o mesmo nome que não possua o sufixo .service e criará dinameicamento uma unidade de serviço a partir deste script. Isso é util para compatibilidade com o SysV. Lembrando que a compatibilidade é bastante abrangente, mas não é 100%.

***

### Seção \[Service\]
Os arquivos de serviço devem incluir na seção **\[Service\]**, que contém informações sobre o serviço e o processo que ele supervisiona. Varias seções que podem ser usadas nesta seção são compartilhadas com outros tipos de unit. Esssas opções estão documentadas em systemd.exec, systtemd.kill e systemd.resource-control. As opções especificas para a seção **\[Service\]** das unit de serverço são as seguintes:

`Type=` Configura o tipo de inicialização do processo para esta unidade de serviço. Que podem ser **simples**, **exec**, **forking**, **oneshot**, **dbus**, **notifyou** e **idle**.

- Se definido **simple** o gerente de seriço considerará a unidade iniciada imediatamente após o processo de serviço principal ter sido iniciado. Espera-se que o processo configurado com ``ExecStart=`` seja o principal processo do serviço. ``Type=simple`` será padrão quando o ``ExecStart=`` for especido, mas o ``Type=`` e ``BusName=`` não for especifica.

- Se definido **exec** é semelhante ao **simple**, mas o gerente de serviço considerará a unidade iniciada imediatamente após a execução do binário principal de serviço. O gerente de serviço atrasará o inicio das unidades acompanhamento até esse ponto. Em outras palavras: **simple** continua com outros trabalhos logo após do retorno do **fork()**, enquanto **exec** não prossegue antes que o **fork()** e o **execve()** retone que os processos dos serviço ter sido bem-sucedido. Observe que isso significa que as linhas de comando systemctl start dos execserviços reportarão falhas quando o binário do serviço não puder ser chamado com êxito (por exemplo, porque o ``User=`` selecionado não existe ou o binário de serviço está ausente.

- Se definido **forking**, espera-se que o processo configurado com ``ExecStart=`` seja chamado **fork()** como parte de sua inicialização. Espera-se que o processo pai saia quando a inicialização estiver concluida e todos os canais de comunicação estiverem configurados. O filho continua sendo executado como o rpocesso de serviço principal e o gerente de serviço considerará a unidade inicada quando o processo pai terminar. Esse é o comportamento dos serviços UNIX tradicioanis. Se essa configuração for usada, é recomendado também usar a opção ``PIDFile=``, para que o systemd possa identificar com segurança o processo principal do serviço. O systemd continuará com as unidades de acompanhamento assim que o processo pai terminhar.

- Se definido **oneshot** é semelhante ao **simple**, no entanto, o gerente de serviço considerará a unidade em funcionamento após a saída do processo principal. Ele iniciará as unidades de acompanhamento o serviço ``RemainAfterExit=``, nunca encontrará no estado da unidade *active*, mas passará diretamente de **activating** para **deactivating** ou **dead**, pois nenhum processo está configurado e deve ser executado continuamente. Em particular, isso significa que após a execução de um serviço desse tipo não será exibido como iniciado posteriormente, mas como morto.

- Se definido **dbus** é semelhante ao **simple**, no entanto, espera-se que o serviço adquira um nome no barramento D-Bus, conforme configurado por ``BusName=``. O **systemd** continuará com as unidades de acompanhamento após a aquisição do nome do barramento D-Bus. As unidades de serviço com esta opção configurada ganham implicitamente dependências na unidade dbus.socket. Este tipo é o padrão se especificado ``BusName=``.

- Se definido **notify** é semelhante ao **exec**, no entanto, espera-se que o serviço envie uma mensagem de notificação vi **sd_notify**, ou uma chamada equivalente quando terminar a inicialização. O systemd continuará com as unidades de acompanhamento após o envio desta mensagem de notificação. Se essa opção for usada, NotifyAccess= deve ser configurada para abrir o acesso ao soquete de notificação fornecido pelo systemd. Se NotifyAcess= estiver ausente ou definido como none, será definido à força como main. Observe que atualmente Type=notify não funcionará se usado em combinação com PrivateNetwork=yes.

- Se definido **idle** é muito semelhante ao **simple**, no entanto, a execução real do programa de serviço é adiada até que todos os trabalhos ativos sejam despachados. Isso pode ser usado para evitar a intercalação da saida dos serviços de shell com a saida de status no console. Observe que esse tipo é útil apenas para melhorar a saída do console, não é util como uma ferramenta geral de pedido de unidades e a efeito desse tipo de serviço está sujeito a um tempo limite de 5s, após o qual o programa de serviço é chamado de qualquer maneira.

Geralmente é recomendável usar serços Type=simple de longa duração sempre que possivel, pois é a opção mais simples e rápida 

`RemainAfterExit=` Adota um valor booleano que especifica se o serviço deve ser considerado ativo, mesmo quando todos os seus processos terminarem. O padrão é **no**.

`GuessMainPID=` Adota um valor booleano que especifica se o systemd deve tentar adivinhar o PID principal de um serviço, se não puder ser determinado com segurança. Esta opção é ignorada, a menos que esteja definido ``Type=forking`` e não esteja definida ``PIDFile=``, pois para os outros tipos ou com um arquivo PID explicitamente configurado, o PID principal é sempre conhecido. O algoritmo de adivinhação pode chegar a conclusões incorretas se um daemon consistir em mais de um processo. Se o PID principal não puder ser determinado, a detecção de falhas e a reinicialização automática de um serviço não funcionarão de maneira confiável. O padrão é yes.

`PIDFile=` Pega um caminho referente ao arquivo PID do serviço. O uso desta opção é recomendado para serviços em que está definido como ``Type=forking``. O caminho especificado normalmente aponta para um arquivo abaixo **/run/**. Se um caminho relativo for especificado, portanto, será prefixado com /run/. O gerente de serviço lerá o PID do processo principal do serviço nesse arquivo após a inicialização do serviço. O gerenciador de serviços não gravará no arquivo configurado aqui, embora o remova após o encerramento do serviço, se ele ainda existir. O arquivo PID não precisa pertencer a um usuário privilegiado, mas, se pertencer a um usuário não privilegiado, serão aplicadas restrições de segurança adicionais: o arquivo **não pode ser um link simbólico** para um arquivo pertencente a um usuário diferente (nem hardlink nem simbolic link), e o arquivo PID deve se referir a um processo que já pertence ao serviço.

`BusName=` Adota um nome de barramento D-Bus em que este serviço pode ser acessado. Esta opção é obrigatória para serviços em que está definido ``Type=`` como **dbus**.

`ExecStart=` Comandos com seus argumentos que são executados quando este serviço é iniciado. O valor é dividido em zero ou mais linhas de comandos, de acordo com as regras descritas abaixo.
> A menos que seja ``Type=oneshot``, exatamente um comando deve ser informado. Quando ``Type=oneshot`` é usado pode ser especificado zero ou mais comandos mais de uma vez com o mesmo efeito. Se a sequencia vazia for atribuida a essa opção, a lista de comandos a ser iniciada será redefinida, as artribuições anteriores dessa opção não terão efeito. Se não for especificado ``ExecStart=`` o serviço deve ter ``RemainAfterExit=yes`` e pelo menos um conjunto de linhas no ``ExecStop=``. Serviço sem ``ExecStart=`` e ``ExecStop=`` não são validos.
>
> Prefixos Executáveis Especiais
> |Preixo|Efeito|
> |------|------|
> |"@" | Se o caminho do executável tiver o prefixo **@**, o segundo token especificado será passado como "argv[0]" para o processo executado (em vez do nome do arquivo real), seguido pelos argumentos adicionais especificados.|
> |"-" | Se o caminho do executável tiver o prefixo **-**, um código de saída do comando normalmente considerado uma falha (ou seja, status de saída diferente de zero ou saída anormal devido ao sinal) será registrado, mas não terá mais efeito e será considerado equivalente ao sucesso.|
> |":" | Se o caminho do executável tiver o prefixo **:**, a substituição da variável de ambiente (conforme descrito na seção "Linhas de Comando" abaixo) não será aplicada.|
> |"+" | Se o caminho do executável tiver o prefixo **+**, o processo será executado com privilégios totais. Neste modo restrições de privilégio configurado com ``User=``, Group=, CapabilityBoundingSet=ou os vários sistema de arquivos opções (tais como namespacing ``PrivateDevices=``, ``PrivateTmp=``) não são aplicadas à linha de comando chamada (mas ainda afeta os outros ``ExecStart=``, ``ExecStop=``, ... linhas).|
> |"!" | Semelhante ao +caracter " " discutido acima, isso permite chamar linhas de comando com privilégios elevados. No entanto, ao contrário de **+** o !caractere " " altera exclusivamente o efeito de ``User=``, ``Group=`` e ``SupplementaryGroups=``, ou seja, apenas as estrofes que afetam as credenciais do usuário e do grupo. Observe que essa configuração pode ser combinada com ``DynamicUser=``, nesse caso, um par dinâmico de usuário / grupo é alocado antes da chamada do comando, mas a alteração de credencial é deixada para o próprio processo executado.|
> |"!!" | Esse prefixo é muito semelhante a **!**, no entanto, apenas afeta sistemas sem suporte para recursos de processo ambiente, ou seja, sem suporte para ``AmbientCapabilities=``. Ele foi projetado para ser usado em arquivos de unidades que se beneficiam dos recursos do ambiente para executar processos com privilégios mínimos, sempre que possível, enquanto permanecem compatíveis com sistemas que não possuem suporte aos recursos do ambiente. Observe que quando **!!** é usado, e um sistema sem suporte à capacidade ambiental é detectado, qualquer configuração ``SystemCallFilter=`` e ``CapabilityBoundingSet=`` sub - rotinas são implicitamente modificadas, a fim de permitir que processos gerados descartem credenciais e capacidades, mesmo que isso esteja configurado para não ser permitido. Além disso, se esse prefixo for usado e um sistema sem suporte à capacidade ambiente for detectado ``AmbientCapabilities=`` será ignorado e não será aplicado. Em sistemas que suportam recursos ambientais, **!!** não tem efeito e é redundante.|
>
> "@", "-", ":" e um de "+" / "!" / "!!" podem ser usados ​​juntos e podem aparecer em qualquer ordem. No entanto, apenas um de "+", "!", "!!" pode ser usado por vez. Note-se que esses prefixos são suportados também para as outras configurações de linha de comando, ou seja ``ExecStartPre=``, ``ExecStartPost=``, ``ExecReload=``, ``ExecStop=`` e ``ExecStopPost=``.
>
>Se mais de um comando for especificado, os comandos serão chamados sequencialmente na ordem em que aparecem no arquivo da unidade. Se um dos comandos falhar (e não for prefixado com " -"), outras linhas não serão executadas e a unidade será considerada com falha.
>
>A menos que Type=forkingseja definido, o processo iniciado por esta linha de comando será considerado o processo principal do daemon.

``ExecStartPre=``, ``ExecStartPost=`` São comandos adicionais que são executados antes ou depois do comando ``ExecStart=`` respectivamente. A sintaxe é a mesma que o ``ExecStart=``, exceto que várias linhas de comandos são permitidas e os comandos são executados um após o outro, em série. Se algum desses comandos falhar e não for prefixado com " -", o restante não será executado e a unidade será considerada com falha.
> Obs. O ``ExecStartPre=`` não pode ser usado para iniciar processos de execução longa. Todos os processos iniciados por processos chamados via ``ExecStartPre=`` serão eliminados antes que o próximo processo de serviço seja executado.
> Nota que, se qualquer um dos comandos especificados no ``ExecStartPre=``, ``ExecStart=`` ou ``ExecStartPost=`` falhar e não são prefixados com "-" ou o tempo limite antes que o serviço é totalmente iniciado, a execução continua com comandos especificados no ``ExecStopPost=``, o comando ``ExecStop=`` é ignorado.

``ExecCondition=`` Comandos opcionais que sõa executados antes do comando em ``ExecStartPre=``. A sintaxe é a mesma que a ``ExecStart=``, exceto que várias linhas de comandos são permitidas e os comandos são executados um após o outro, em série.

>O comportamento é como um ``ExecStartPre=`` híbrido de verificação de condições, quando um comando ``ExecCondition=`` sai com o código de saida 1 a 254 os comandos restantes são ignorados e a unidade **não** é marcada como falha. No entanto se um comando ``ExecCondition=`` sair com 255 ou de forma anormal (por exemplo, tempo limite, interrupção por um sinal, etc) a unidade será considerada com falha e os comandos restantes serão ignorados. O código de saida 0 ou os correspondentes ``SucessExitStatus=`` continuarão a execução para o seguinte comando.
>As mesmas recomendações sobre a não execução de processos de execução lonfa ``ExecStartPre=`` também se aplicam a ``ExecCondition=``. ``ExecCondition=`` também executará os comandos ``ExecStopPost=``, como parte da interrupção do serviço, no caso de sidas diferentes de zero ou anormais, como as descritas acima.

``ExecReload=`` Comandos a serem executados para acionar um recarremanto de configuração no serviço. Esse argumento usa várias linhas de comando, seguindo o mesmo esquema descrito ``ExecStart=``. O uso dessa configuração é opcional. A substituição do especificador e da variável de ambiente é suportada aqui, seguindo o mesmo esquema que para ``ExecStart=``.

``ExecStop=`` Comandos a serem executados para interromper o serviço iniciado via ``ExecStart=``. Esse argumento usa várias linhas de comando, seguindo o mesmo esquema descrito ExecStart=. O uso dessa configuração é opcional. Após a execução dos comandos configurados nesta opção, fica implicito que o serviço é interrompido e todos os processos restantes são finalizados de acordo com a configuração ``KillMode=``. Se essa opção não for especificada, o processo será encerrado enviando o sinal especificado em ``KillSignal=`` quando a parada de serviço for solicitada. A substituição do especificador e da variável de ambiente é suportada.
> Geralmente não é necessário esepecificar um comando para essa configuração que solicita apenas que que o serviço seja encerrado (por exemplo, enfileirando algum tipo de sinal de finalização), mas não espere que isso seja feito. Como os processos restantes são serviços são eliminados de acordo com ``KillMode=`` e ``KillSignal=`` conforme descrito acima imediatamente após a saida do comando, isso pode não resultar em uma parada limpa. O comando especificado deve, portanto, ser uma operação sincrona não assincrona.
> 
> Os comandos especificados em ``ExecStop=`` são executados somente quando o serviço foi iniciado com exito primeiro. Eles não são invocados se o serviço nunca foi iniciado, ou no caso da sua start-up falhar, por exemplo, porque qualquer um dos comandos especificados no ``ExecStart=``, ``ExecStartPre=`` ou ``ExecStartPost=`` falhou e não foram prefixados com **-** ou expirou. Use ``ExecStopPost=`` para chamar comandos quando um serviço falhou ao iniciar corretamente e é desligado novamente. Observe também que a operação de parada sempre é executada se o serviço for iniciado com exito, mesmo se os processo no serviço terminarem sozinhos ou foram mortos. Os comandos de parada devem estar preparados para lidar com esse caso. $MAINPID será desabilitado se o systemd souber que o processo principal terminou no meomento em que os comandos de parada são chamados.
>
> Solicitações de reinicialização de serviço são implementadas como operações de parada seguidas por operações de inicio. Isso significa que ``ExecStop=`` e ``ExecStopPost=`` são executados durante uma operação de reinicialização do serviço.
>
> É recomendavel usar essa configuração para comandos que se comunicam com o serviço que solicita finalização limpa. Para as etapas de limpeza post mortem, use em vez disso ``ExecStopPost=``.

``ExecStopPost=`` Comandos adicionais que são executados após a interrupção do serviço. Isso inclui casos em que os comandos configurados em ``ExecStop=`` foram usados, onde o serviço não possui nenhum ``ExecStop=`` definido ou onde o serviço foi encerrado inesperadamente. Esse argumento utiliza várias linhas de comando, seguindo o mesmo esquema descrito para ExecStart=. O uso desas configurações é opcional. A substituição do espeficador e das variavel de ambiente é suportada. Observe que - ao contrário de ExecStop=- os comandos esepcificados com esta configuração são chamados quando um serviço falha ao iniciar corretamente e é desligado novamente.
> É recomendado usar essa configuração para operações de limpeza que devem ser executadas mesmo quando o serviço falhou ao iniciar corretamente. Os comandos configurados com essa configuração precisam poder operar, mesmo se o serviço falhar na inicialização até a metade e deixar dados incompletamente inicializados. Como os processos do serviço já foram finalizados quando os comandos especificados com esta configuração são executados, eles não devem tentar se comunicar com eles.
>
> Note-se que todos os comandos que são configurados com essa configuração são invocados com o código de resultado do serviço, bem como o principal processo de código de saída e status, conjunto nas variaveis de ambiente $SERVICE_RESULT, $EXIT_CODE e $EXIT_STATUS.

``RestartSec=`` Configura o tempo de suspensão antes de reiniciar um serviço (conforme configurado com Restart=). Obtém um valor sem unidade em segundos ou um valor de intervalo de tempo como "5min 20s". O padrão é 100ms.

``TimeoutStartSec=`` Configura o tempo para aguardar a inicialização. Se um serviço daemon não sinalizar a conclusão da inicialização dentro do tempo configurado, o serviço será considerado como falha e será encerrado novamente. Obtém um valor sem unidade em segundos ou um valor de intervalo de tempo como "5min 20s". Passe **infinity** para desativar a logica do tempo limite.

``TimeoutStopSec=`` Esta opção serve para dois propósitos. Primeiro, ele configura o tempo de espera para cada comando ``ExecStop=``. Se algum deles expirar, os comandos subsequentes serão ignorados e o serviço será encerrado por **SIGTERM**, Se nenhum comando ``ExecStop=`` for especificado, o serviço obtém imediatamente o **SIGTERM**. Segundo, ele configura o tempo para aguardar a interrupção do serviço. Se não terminar no tempo especificado, será encerrado à força por **SIGKILL**. Obtém um valor se unidade em segundos ou um valor de intervalo de tempo como "5min 20s". Passe **infinity** para desativar a logica do tempo limite. O padrão ``DefaultTimeoutStopSec=`` é do arquivo de configuração do gerenciador. Para mais detalhes sobre o arquivo **system.conf** acesse o [link](https://www.freedesktop.org/software/systemd/man/systemd-system.conf.html)

``TimeoutAbortSec=`` Essa opção configura o tempo de espera pelo término do serviço quando foi interrompido devido a um tempo limite do watchdog (consulte ``WatchdogSec=``). Se o serviço tiver um curto, TimeoutStopSec= essa opção poderá ser usada para dar mais tempo ao sistema para escrever um dump principal do serviço. Após o termino do serviço será forçasamente terminado pro SIGKILL (consulte ``KillMode=``). O arquivo principal será truncado nesse caso. Use TimeoutAbortSec= para definir um tempo limite razoavel para o dumping de núcleo por serviço que seja grande o suficiente para gravar todos os dados esperados e, ao mesmo tempo, curto o suficiente para lidar com a falha do serviço no devido tempo.
> Recebe um valor sem unidade em segundos ou um valor de intervalo de tempo como "5min 20s". Passe um valor vazio para pular o controle dedicado de abortar o controle de tempo limite e voltar atrás ``TimeoutStopSec=``. Passe **infinity** para desativar a lógica do tempo limite. O padrão é o DefaultTimeoutAbortSec= do arquivo de configuração do gerenciador. Consulte [systemd-system.conf](https://www.freedesktop.org/software/systemd/man/systemd-system.conf.html)

``TimeoutSec=`` Uma abreviação para a configurar ambos TimeoutStartSec= e TimeoutStopSec= para o valor especificado.

``TimeoutCleanSec=`` Configura um tempo limite na operação de limpeza solicitada através do **systemctl clean**. Leva os valores de tempo usuais e os padrões par ainfinity, ou seja por padrão, nenhum tempo limite é aplicado. Se um tempo limite estiver configurado, a operação de limpeza será cancelada à força quando o tempo limite for atingido, potencialmente deixando recursos no disco.

``RuntimeMaxSec=`` Configura um tempo máximo para a execução do serviço. Se isso for usado e o serviço estiver ativo por mais tempo que o tempo especificado, ele será encerrado e colocado em um estado de falha. Observe que essa configuração não afeta os serviços ``Type=oneshot``, pois eles terminam imediatamente após a conclução da ativação. Passe **infinity** (padrão) para configurar nenhum limite de tempo de execução.

``WatchdogSec=`` Configura o tempo limite do watchdog para um serviço. O watchdog é ativado quando a inicialização é concluida. O serviço deve chamar sd_notify regularmente com o **WHATCHDOG=1** (ou seja, o **ping ativo**). Se o tempo entre duas dessas chamadas for maior que o tempo configurado, o serviço será colocado em um estado com falha e será encerrado com **SIGABRT** (ou o sinal especificado por ``WatchdogSignal=``). Ao definir a ``Restart=`` **on-failure**,**on-watchdog**, **on-abnormal** ou **always**, o serviço será reiniciado automaticamente. O tempo configurado aqui será passado para o processo de serviço executado na variavel de ambiente WATCHDOG_USEC=. Isso permite que os daemons ativem automatiamente a logica de ping keep-alive se o suporte do watchdog estiver ativado para o serviço. Se essa opção for usada, o NotifyAccess= deve ser configurada para abrir o acesso ao soquete de notificação fornecido pelo systemd. Se o NotifyAccess= não estiver definido, será impplicitamente definido como **main**. O padrão é 0, que desativa esse recurso. O serviço pode verificar se o gerente de serviço espera notificações de manutemção do watchdog. Veja [sd_watchdog_enabled (3)]() para detalhes. O [sd_event_set_watchdog (3)]() pode ser usado para ativar o suporte à notificação automática de watchdog.

``Restart=`` Configura se o serviço deve ser reiniciado quando o processo do serviço é encerrado, interrompido ou atingido um tempo limite. O processo de serviço pode ser o processo do serviço principal, mas também pode ser um dos processos especificados com o ExecStartPre=, ExecStartPost=, ExecStop=, ExecStopPost= ou ExecReload=. Quando o kill do processo é resultado da operação do systemd (por exemplo, parada ou reinicio do serviço), o serviço não será reiniciado. Os tempos limite incluem a falta do prazo "watch-alive ping" do watchdog e um tempo limite para iniciar, recarregar e parar a operação.
> Recebe um dos **no**, **on-success**, **on-failure**, **on-watchdog**, **on-abnormal**, **on-abort** ou **always**. Se definido como **no** (padrão), o serviço não será reiniciado. Se deifnido como **on-success**, ele será reiniciado apenas quando o processo de serviço terminar corretamente. Neste contexto, uma saída limpa significa um código de saída 0, ou um dos sinais SIGHUP, SIGINT, SIGTERM ou SIGPIPE. 
> Se definido como on-failure, o serviço será reiniciado quando o processo sair com um código de saida diferente de zero.
> Se definido como an-abnormal, o serviço será reiniciado quando o processo for finalizado por um sinal quando uma operação atingir o tempo limite ou quando o tempo limite do watchdog for acionado.
> Se definido como on-abort, o serviço será reiniciado apenas se o processo dfe serviço terminar devido a um sinal não capturado não especificado como um status de saída limpo.
> Se definido como on-watchdog, o seviço será reiniciado apenas se o tempo limite do watchdog para o serviço expirar.
> Se definido como always, o serviço será reiniciado, independente de sair ou não de forma limpa, ter sido finalizado de forma anormal por um sinal ou atingir um tempo limite.

Causas de saida e o efeito das configurações Restart=.

|   Reiniciar configurações / causas de saída   | no  | always  |   on-success  |   on-failure  |   on-abnormal     |   on-abort    |   on-watchdog |
|-----------------------------------------------|-----|---------|---------------|---------------|-------------------|---------------|---------------|
|   Código ou sinal de saída limpo              | -   | X       |   X           |   -           |   -               |   -           |   -           | 
|   Código de saída impuro                      | -   | X       |   -           |   X           |   -               |   -           |   -           |
|   Sinal impuro                                | -   | X       |  	-           | 	X           |	X               |   X           |   -           |
|   Tempo esgotado                              | -   |	X       |   -           |   X           |   X               |   -           |   -           |
|   Cão de guarda                               | -   | X       |   -           |   X           |	X               |   -           |   X           |
|-----------------------------------------------|-----|---------|---------------|---------------|-------------------|---------------|---------------|

> Como exceções à configuração acima, o serviço não será reiniciado se o código ou sinal de saida for especificado em RestartPreventExitStatus= ou se o serviço for parado com **systemctl stop** ou uma operação equivalente. Além disso, os serviços sempre serão reiniciados se o código ou sinal de saida for especificado em RestartForceExitStatus=
> Se a reinicialização do serviço está sujeita à limitação da taxa de inicialização da unidade configurada com StartLimitInternalSec= e StartLimitBurst=, Um serviço reiniciado entra no estado de falha somente depois que os limites de inicio são atingidos.
> Definir isso como on-failure é a opção recomendada para serviço de longa execução, a fim de aumentar a confiabilidade, tentando a recuperação automática de erros. Para serviços que poderão terminar por sua própria escolha (e evitar a reinicialização imediata), on-abnormal é uma escolha alternativa.

``SuccessExitStatus=`` Recebe uma lista de definiçoes de status de saida que quando devolvido pelo processo de serviço principal, serão considerados término bem sucedido, além do código normal sucesso exit 0 e os sinais SIGHUP, SIGINT, SIGTERM e SIGPIPE. As definições de status de saida podem ser códigos de saida numericos, nomes de codigos de terminação ou nomes de sinais de terminação, separados por espaços.
> **Um serviço com a configuração SuccessExitStatus=** 
> Os códigos de saida 75 (TEMPFAIL), 250 e o sinal de terminação SIGKILL são considerados terminações de serviço limpas.
> 
> Nota: Os codigos de saida systemd-analyse podem ser usados para listar codigos de saida e converter enter valores e nomes de codigos numericos.

``RestartPreventExitStatus=`` Faz uma lista de definições de status de saida, quando retornadas pelo processo de serviço principal impedirão a reinicialização automática do serviço independentemente da configuração de reinicialização configurada com Restart=. As definições de status de saida podem ser código de saida numéricos ou nomes de sinais de terminação e são separadas por espaços. O padrão é a lista vazia, para que, por padrão, nenhum status de saida seja excluido da logica de reinicialização configurada. Por exemplo:

> RestartPreventExitStatus=1 6 SIGABRT

Garante que os códigos de saida 1 e 6 e sinal de terminação SIGABR não resultem na reinicialização do serviço. Essa opção pode aparecer nais de uma vez; nesse caso, a lista de status de prevenção de reinicialização é mesclada. Se a sequencia vazia for atribuida a esta opção, a lista será redefinida e todas as atribuições anteriores dessa opção não terão efeito.

> Note-se que esta configuração não tem efeito sobre os processos configurados por meio de ExecStartPre=, ExecStartPost=, ExecStop=, ExecStopPost= ou ExecReload=, mas apenas no processo principal, ou seja, quer a um invocado por ExecStart= ou (dependendo Type=, PIDFile=, ...) o processo principal configurado de outra forma.

``RestartForceExitStatus=`` Faz uma lista de definições de status de saída que quando retornadas pelo processo principal de serviço forçarão a reinicialização automática do serviço, independente da configuração de reinicialização configurada com ``Restart=``. O formato do argumento é semelhante a ``RestartPreventExitStatus=``.

``RootDirectoryStartOnly=`` Adota um argumento booleano. Se for **true**, o diretório raiz, como configurado com a opção ``RootDirectory=``, só é aplicado ao processo que começou com ``ExecStart=``, e não para os outros comandos ``ExecStartPre=``, ``ExecStartPre=``, ``ExecReload=``, ``ExecStop=``, e ``ExecStopPost=``. Se for **false**, a configuração é aplicada a todos os comandos configurados da mesma mameira. O padrão é **false**.

``NonBlocking=`` Defina o sinalizador O_NONBLOCK para todos os file-descriptor passados por meio da ativação baseada em soquete. Se verdadeiro, todos os file-descriptor >=3(ou seja, todos, exceto stdin, stdout, stderr), excluindo os passdos pela logica de armazenamento do descritor de arquivo (), terão o sinalizador O_NONBLOCK deifinido e, portanto, estarão no modo NON-BLOCKING. Essa opção é util apenas em conjunto com uma unidade de soquete, conforme descrito em systemd.socket(5) e não afeta os file-descriptor que foram salvos anteriormente no repositório de file-descriptor, por exemplo. O padrão é **false**.

``NotifyAccess=`` Controla o acesso ao soquete de notificação do status do serviço, conforme acessível pela chamada **sd_notify**. Recebe um dos parametros **none** (padrão), **main**, **exec** ou **all**. Se **none** nenhuma atualizaçãode status do daemon for aceita nos processos de serviço, todas as mensagens de atualização de status serão ignoradas. Se **main**, apenas as atualizações de serviço enviadas do processo principal do serviço são aceitas. Se **exec**, apenas as atualizações de serviço enviadas de qualquer um dos processos principais ou de controle originários de um dos comandos *Exec\*=* são aceitas. Se **all** todas as atualizações de serviços de todos os membros do grupo de controle do serviço serão aceitas. Esta opção deve ser configurada para abrir o acesso ao soquete de notificação ao usar ``Type=notify`` ou ``Watchdog=``. Se essas opções forem usadas, mas ``NotifyAccess=`` não estiver configuradas, elas serão implicitamente definidas como **main**. 
> Observe que as notificações **sd_notify()** podem ser atribuídas corretamente apenas se o processo de envio ainda estiver disponível no momento em que o PID 1 processar a mensagem ou se o processo de envio for explicitamente rastreado em tempo de execução pelo agente de serviço. O último é o caso se o gerente de serviço originalmente iniciou o processo, ou seja, em todos os processos correspondentes **main** ou **exec**. Por outro lado, se um processo auxiliar da unidade enviar uma mensagem **sd_notify()** e sair imediatamente, o gerente de serviço poderá não ser capaz de atribuir adequadamente a mensagem à unidade e, portanto, a ignorará, mesmo que esteja definida para ela ``NotifyAccess=all``.

``Sockets=`` Especifica o nome das inidades de soquete em que este serviço herdará os descritores de arquivo de soquete a partir de quando o serviço for iniciado. Normalmente, não deve ser necessário usar essa configuração, pois todos os descritores de arquivo de soquete cuja unidade compartilha o mesmo nome que o serviço (sujeito ao sufixo do nome da unidade diferente) são passados para o processo gerado.
> Observe que os mesmos descritores de arquivo de soquete podem ser passados para vários processos simultaneamente. Também que um serviço diferente pode ser ativado no tráfego de soquete de entrada daquele que está configurado para herdar os descritores de arquivo de soquete. Em outras palavras: a configuração ``Service=`` de unidades **.socket** não precisa corresponder ao inverso da configuração ``Sockets=`` a que se refere **.service**.
> Esta opção pode aparecer mais de uma vez; neste casoz a lista de unidades de soquete é mesclada. Que uma vez definido, a limpeza da lista de soquetes novamente (por exemplo, atribuido a cadeia vazia a esta opção) não é suportada.


``OOMPolicy=`` Configure a política do killer sem memória (OOM). No Linux, quando a memória se torna escassa, o kernel pode decidir interromper um processo em execução para liberar memória e reduzir a pressão da memória. Essa configuração recebe um dos parametros **continue**, **stop** ou **kill**. Se definido como **continue** e um processo do serviço é elimidao pelo killer OOM do kernel, isso é registrado, mas o serviço continua em execução. Se definido como **stop** o evento fo registrado, mas o serviço será encerrado corretamente pelo gerente de serviço. Se definido como **kill** e um dos processos do serviço é eliminado pelo killer do OOM, o kernel também é instruido a eliminar todos os processos restantes do serviço. O padrão é a configuração ``DefaultOOMPolicy=``, exceto nos serviços em que está Delegate= ativado, e o padrão é **continue**.
> Use a configuração ``OOMScoreAdjust=`` para definir se os processos da unidade devem ser considerados candidatos preferenciais ou menos preferidos para finalização do processo pela lógica do killer do Linux OOM.


***

## Complementares
sytemctl clean
### Kill
``KillMode=``

### 

### Ulimit
``LimitCPU=, LimitFSIZE=, LimitDATA=, LimitSTACK=, LimitCORE=, LimitRSS=, LimitNOFILE=, LimitAS=, LimitNPROC=, LimitMEMLOCK=, LimitLOCKS=, LimitSIGPENDING=, LimitMSGQUEUE=, LimitNICE=, LimitRTPRIO=, LimitRTTIME=`` Defina limites flexíveis em vários recursos para processos executaddos. Os limites de recursos podem se especificados em dois formatos: como valor unico para definir um limite flexível e rigido especifico para o mesmo valor ou com par separado por dois pontos **soft:hard** para definir ambos os limites individualmente (por exemplo, ```LimitAS=4G:16G``). Use a sequência **infinity** para configurar nenhum limite em um recurso especifico. Os sufixos multiplicativos K, M, G, T, P e E (até a base 1024) podem ser usados para limites de recursos medidos em bytes (por exemplo ``LimitAS=16G``). Para os limites referentes aos valores de tempo, as unidades de tempo usuais ms, s, min, h e assim por diante podem ser usadas. Observe que, se nenhuma unidade de tempo for especificada para LimitCPU a unidade padrão de segundos, está implicita, enquanto LimitRTTIME= a inidade padrçao de microssegundos está implicita. Além disso observe que a granularidade efetiva fos limites podem influenciar sua aplicação. Por exemplo os prazos especificados para LimitCPU= são arredondaos implicitamente para múltiplos de 1s. Para LimitNICE= o valor pode ser especificado em duas sintaxes: se prefixado como **+** ou **-**, o valor será entendido como um bom valor normal do Linux no intervalo -20..19. Se não for prefixado assim, o valor será entendido como parâmetro de limite de recurso bruto no intervalo de 0 a 40 (com 0 sendo equivalente a 1).


|   Diretiva        |   Ulimit equivalente  |   Unidade                     |
|-------------------|-----------------------|-------------------------------|
| LimitCPU=         | ulimit -t             | Seconds                       |
| LimitFSIZE=       | ulimit -f             | Bytes                         |
| LimitDATA=        | ulimit -d             | Bytes                         |
| LimitSTACK=       | ulimit -s	            | Bytes                         |
| LimitCORE=        | ulimit -c             | Bytes                         |
| LimitRSS=         | ulimit -m             | Bytes                         |
| LimitNOFILE=      | ulimit -n             | Number of File Descriptors    |
| LimitAS=          | ulimit -v             | Bytes                         |
| LimitNPROC=       | ulimit -u             | Number of Processes           |
| LimitMEMLOCK=     | ulimit -l             | Bytes                         |
| LimitLOCKS=       | ulimit -x             | Number of Locks               |
| LimitSIGPENDING=  | ulimit -i             | Number of Queued Signals      |
| LimitMSGQUEUE=    | ulimit -q             | Bytes                         |
| LimitNICE=        | ulimit -e             | Nice Level                    |
| LimitRTPRIO=      | ulimit -r             | Realtime Priority             |
| LimitRTTIME=      | No equivalent         | Microseconds                  |

***
```ini
## licenserver.service
[Unit]
Description=License Server Virtual PROD
After=network.target
StartLimitIntervalSec=0

[Service]
Type=simple
Restart=on-failure
RestartSec=1
User=root
ExecStart=/bin/bash /etc/init.d/service.sh start
KillMode=mixed
PIDFile=/var/run/licensesever.pid
LimitNOFILE=65536
LimitSTACK=1024k
LimitCORE=infinity
LimitFSIZE=infinity
LimitCPU=infinity
LimitAS=infinity

[Install]
WantedBy=multi-user.target
```

```ini
# /etc/systemd/system/dbaccess-prd.service
[Unit]
Description=DBAccess 7890
After=network.target
StartLimitIntervalSec=0

[Service]
Type=simple
Restart=on-failure
RestartSec=1
User=root
ExecStart=/totvsdbaccess/multi/dbaccess64
EnvironmentFile=/etc/systemd/system/dbaccess.service.d/dbaccess.conf
PIDFile=/var/run/dbaccess.pid
LimitNOFILE=65536
LimitSTACK=1M
LimitCORE=infinity
LimitFSIZE=infinity
LimitCPU=infinity
LimitAS=infinity

[Install]
WantedBy=multi-user.target
Alias=dbaccess7890.sevice
```
```ini
# /etc/systemd/system/dbaccess-prd.service.d/dbaccess-prd.conf

ORACLE_SID=orcl
ORACLE_HOME=/u01/app/oracle/product/12.2.0.1/db1
TNS_ADMIN=${tns_admin}
CLASSPATH=$ORACLE_HOME/JRE:$ORACLE_HOME/jlib:$ORACLE_HOME/rdbms/jlib:$ORACLE_HOME/network/jlib
LD_LIBRARY_PATH=$ORACLE_HOME:/lib:/usr/lib:/usr/local/lib:/totvsdbaccess/multi:$LD_LIBRARY_PATH
PATH=$ORACLE_HOME:$PATH

```

```ini
## protheus-master.service
[Unit]
Description=Protheus Master PROD
Requires=network.target
After=dbaccess.target
StartLimitIntervalSec=0

[Service]
Type=simple
Restart=on-failure
RestartSec=1
User=root
ExecStart=/bin/bash /etc/init.d/service.sh start
KillMode=mixed
PIDFile=/var/run/protheus-master.pid
LimitNOFILE=65536
LimitSTACK=1024k
LimitCORE=infinity
LimitFSIZE=infinity
LimitCPU=infinity
LimitAS=infinity

[Install]
WantedBy=multi-user.target
```

```ini
## protheus-slv.service
[Unit]
Description=Protheus Slave PROD
Requires=network.target
After=dbaccess.target protheus-master.target
StartLimitIntervalSec=0

[Service]
Type=simple
Restart=on-failure
RestartSec=1
User=root
ExecStart=/bin/bash /etc/init.d/service.sh start
KillMode=mixed
PIDFile=/var/run/protheus-slv.pid
LimitNOFILE=65536
LimitSTACK=1024k
LimitCORE=infinity
LimitFSIZE=infinity
LimitCPU=infinity
LimitAS=infinity

[Install]
WantedBy=multi-user.target
```