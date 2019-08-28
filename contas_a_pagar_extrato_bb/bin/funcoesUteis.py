import unicodedata
import re
import datetime

def removerAcentosECaracteresEspeciais(palavra):
    # Unicode normalize transforma um caracter em seu equivalente em latin.
    nfkd = unicodedata.normalize('NFKD', palavra).encode('ASCII', 'ignore').decode('ASCII')
    palavraTratada = u"".join([c for c in nfkd if not unicodedata.combining(c)])

    # Usa expressão regular para retornar a palavra apenas com valores corretos
    return re.sub('[^a-zA-Z0-9.!+:=)?$(/*,\-_ \\\]', '', palavraTratada)

def trocaCaracteresTextoPraLetraX(palavra):
    # Unicode normalize transforma um caracter em seu equivalente em latin.
    nfkd = unicodedata.normalize('NFKD', palavra).encode('ASCII', 'ignore').decode('ASCII')
    palavraTratada = u"".join([c for c in nfkd if not unicodedata.combining(c)])

    # Usa expressão regular para retornar a palavra apenas com valores corretos
    return re.sub('[^0-9\\-/]', 'X', palavraTratada)

# Minimaliza, ou seja, transforma todas as instancias repetidas de espaços em espaços simples.
#   Exemplo, o texto "  cnpj:      09.582.876/0001-68    Espécie Documento          Aceite" viraria
#   "cnpj: 09.582.876/0001-68 Espécie Documento Aceite"
#
# Nota: Ele faz um trim do texto também
def minimalizeSpaces(text):
    _result = text
    while ("  " in _result):
        _result = _result.replace("  ", " ")
    _result = _result.strip()
    return _result

def trataCampoTexto(valorCampo):
    valorCampo = str(valorCampo)
    try:
        return minimalizeSpaces(removerAcentosECaracteresEspeciais(valorCampo.strip().upper()))
    except Exception:
        return ""

def trataCampoNumero(valorCampo):
    return re.sub('[^0-9]', '', valorCampo)

def trataCampoDecimal(valorCampo, qtdCasaDecimais=2):
    valorCampo = str(valorCampo)
    valorCampo = re.sub('[^0-9.,]', '', valorCampo)
    if valorCampo.count(',') > 0 and valorCampo.count('.') > 0:
        valorCampo = valorCampo.replace('.','')

    if ',' in valorCampo:
        valorCampo = valorCampo.replace(',','.')
    
    try:
        valorCampo = float(valorCampo)
    except Exception as e:
        valorCampo = float(0)

    return valorCampo

def retornaCampoComoData(valorCampo, formatoData=1):
    """
    :param valorCampo: Informar o campo string que será transformado para DATA
    :param formatoData: 1 = 'DD/MM/YYYY' ; 2 = 'YYYY-MM-DD'
    :return: retorna como uma data. Caso não seja uma data válida irá retornar um campo vazio
    """
    valorCampo = str(valorCampo).strip()

    if formatoData == 1:
        formatoDataStr = "%d/%m/%Y"
    elif formatoData == 2:
        formatoDataStr = "%Y-%m-%d"

    try:
        return datetime.datetime.strptime(valorCampo, formatoDataStr).date()
    except ValueError:
        return None

def transformaCampoDataParaFormatoBrasileiro(valorCampo):
    """
    :param valorCampo: informe o campo data, deve buscar da função retornaCampoComoData()
    :return: traz a data no formato brasileiro (dd/mm/yyyy)
    """
    try:
        return valorCampo.strftime("%d/%m/%Y")
    except AttributeError:
        return None

def buscaPosicaoCampo(campoCabecalho, nomeCampo='', posicaoCampo=0):
    nomeCampo = str(removerAcentosECaracteresEspeciais(nomeCampo)).upper()
    try:
        numPosicaoCampo = campoCabecalho[nomeCampo]
    except KeyError:
        numPosicaoCampo = posicaoCampo

    return numPosicaoCampo