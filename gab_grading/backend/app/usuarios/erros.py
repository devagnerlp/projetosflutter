class ErroDeUsuario(Exception):
    """Qualquer recusa ligada a contas e login. Quem traduz para HTTP e' o main.py."""

class EmailJaCadastrado(ErroDeUsuario):
    """Ja' existe uma conta com esse e-mail."""

class CredenciaisInvalidas(ErroDeUsuario):
    """E-mail ou senha errados, ou token invalido, ou conta desativada.

    A mensagem nao diz qual dessas causas ocorreu, de proposito: dizer
    "senha errada" confirma que o e-mail existe; dizer "conta desativada"
    tambem confirma. E' isso que quem esta' adivinhando quer saber.
    """