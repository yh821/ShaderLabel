using UnityEngine;
using System.Collections.Generic;
using UnityEngine.UI;
using System.Net;

public class GetIPAddress : MonoBehaviour {
	public Text mText;
	// Use this for initialization
	void Start () {
		string content = "ipAddress:" + Network.player.ipAddress;
		content += '\n' + GetLocalIP ();
		var addressList = GetLocalIpAddress ();
		foreach (var address in addressList) {
			content += '\n' + address;
		}
		mText.text = content;
	}
	
	// Update is called once per frame
	void Update () {
		
	}

	public static string GetLocalIP()
	{
		try {
			IPHostEntry IpEntry = Dns.GetHostEntry (Dns.GetHostName ());
			foreach (IPAddress item in IpEntry.AddressList) {
				if (item.AddressFamily == System.Net.Sockets.AddressFamily.InterNetwork) {
					return item.ToString ();
				}
			}
			return "";
		} catch {
			return "";
		}
	}

	/// <summary>
	/// 获取本机所有ip地址
	/// </summary>
	/// <param name="netType">"InterNetwork":ipv4地址，"InterNetworkV6":ipv6地址</param>
	/// <returns>ip地址集合</returns>
	public static List<string> GetLocalIpAddress(string netType=null)
	{
		string hostName = Dns.GetHostName ();                    //获取主机名称  
		IPAddress[] addresses = Dns.GetHostAddresses (hostName); //解析主机IP地址  

		List<string> IPList = new List<string> ();
		if (string.IsNullOrEmpty (netType)) {
			for (int i = 0; i < addresses.Length; i++) {
				IPList.Add (addresses [i].AddressFamily.ToString () + ":" + addresses [i].ToString ());
			}
		} else {
			//AddressFamily.InterNetwork表示此IP为IPv4,
			//AddressFamily.InterNetworkV6表示此地址为IPv6类型
			for (int i = 0; i < addresses.Length; i++) {
				if (addresses [i].AddressFamily.ToString () == netType) {
					IPList.Add (addresses [i].ToString ());
				}
			}
		}
		return IPList;
	}

}
