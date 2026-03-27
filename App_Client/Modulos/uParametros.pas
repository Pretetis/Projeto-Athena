unit uParametros;

interface
uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, DateUtils, StrUtils,
  System.JSON, REST.Types, REST.Client, REST.Authenticator.Basic, REST.Response.Adapter,
  System.Generics.Collections;

var
  RestClient: TRestClient;
  RestResponse: TRestResponse;
  RestRequest: TRestRequest;
  Authenticator: THTTPBasicAuthenticator;
  JSONValue: TJSONValue;
  JSONObject: TJSONObject;
  JSONArray: TJSONArray;

  mNomeUsuario: string;
  mUsuario: string;
  mSetor: string;
  mSenha: string;
  mMaqID: Integer;
  mCncID: Integer;
  mCncCnc: Integer;
  mPrcID: Integer;
  mQtdePendente: Double;
  mData: string;
  mHora: string;
  mDataHora: string;
  mProtocolo: string;
  mMaterialID: Integer;
  mGasID: Integer;
  ListaAlarmesIgnorados: TList<Integer>;
  mAlr_id: Integer;
  mProgramador: Integer;

const
    userName = ' ';
    password = ' ';

  endPoint       = 'http://192.168.0.142:3000';  //Testes Computador DEV

//    endPoint       = '';   //produção


implementation


initialization
  ListaAlarmesIgnorados := TList<Integer>.Create;
  mUsuario := 'Shallan Davar';
finalization
  ListaAlarmesIgnorados.Free;


end.
