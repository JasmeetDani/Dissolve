using UnityEngine;

public class Rotate : MonoBehaviour
{
    void Update()
    {
        transform.Rotate(Vector3.up, 20 * Time.deltaTime);    
    }
}